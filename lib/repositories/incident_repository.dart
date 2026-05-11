import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
// Hide our local StorageException — we want Supabase's here so we can read
// its `.message` for upload failures.
import '../exceptions/app_exceptions.dart' hide StorageException;
import '../models/incident.dart';
import '../models/incident_attachment.dart';
import '../models/incident_person.dart';

class IncidentRepository {
  IncidentRepository(this._client);

  final SupabaseClient _client;

  Future<List<Incident>> listIncidents({
    String? search,
    String? category,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      dynamic query = _client
          .from(AppConfig.incidentsTable)
          .select()
          .eq('is_active', true);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      if (from != null) {
        query = query.gte('occurred_at', _yyyymmdd(from));
      }
      if (to != null) {
        query = query.lte('occurred_at', _yyyymmdd(to));
      }
      if (search != null && search.trim().isNotEmpty) {
        final String pattern = '%${search.trim()}%';
        query = query.or(
          'title.ilike.$pattern,description.ilike.$pattern,location_text.ilike.$pattern',
        );
      }
      query = query.order('occurred_at', ascending: false).limit(500);

      final List<dynamic> rows = await query as List<dynamic>;
      return rows
          .map((dynamic r) => Incident.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to load incidents', e);
      }
      throw DatabaseException('Failed to load incidents: $e');
    }
  }

  Future<Incident> getIncidentById(String id) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(AppConfig.incidentsTable)
          .select('*, incident_attachments(*), incident_persons(*)')
          .eq('id', id)
          .single();
      return Incident.fromJson(row);
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        throw NotFoundException('Incident not found');
      }
      if (e is PostgrestException) {
        throw DatabaseException('Failed to load incident', e);
      }
      throw DatabaseException('Failed to load incident: $e');
    }
  }

  /// Returns the newly-created incident id.
  Future<String> createIncident(Incident draft) async {
    final String? uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const UnauthorizedException('Sign in required to create incidents');
    }
    try {
      final Map<String, dynamic> row = await _client
          .from(AppConfig.incidentsTable)
          .insert(draft.toJsonForWrite(createdByUid: uid))
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to create incident', e);
      }
      throw DatabaseException('Failed to create incident: $e');
    }
  }

  Future<void> updateIncident(Incident incident) async {
    final String? uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const UnauthorizedException('Sign in required to update incidents');
    }
    try {
      await _client
          .from(AppConfig.incidentsTable)
          .update(
              incident.toJsonForWrite(createdByUid: incident.createdBy ?? uid))
          .eq('id', incident.id);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to update incident', e);
      }
      throw DatabaseException('Failed to update incident: $e');
    }
  }

  /// Soft delete: flip is_active to false.
  Future<void> deactivateIncident(String id) async {
    try {
      await _client
          .from(AppConfig.incidentsTable)
          .update(<String, dynamic>{'is_active': false})
          .eq('id', id);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to remove incident', e);
      }
      throw DatabaseException('Failed to remove incident: $e');
    }
  }

  // ============================================================
  // Persons
  // ============================================================
  Future<IncidentPerson> addPerson({
    required String incidentId,
    String? bookingNo,
    String? mniNo,
    String? label,
    int sortOrder = 0,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'incident_id': incidentId,
      'booking_no':
          (bookingNo != null && bookingNo.trim().isNotEmpty) ? bookingNo.trim() : null,
      'mni_no':
          (mniNo != null && mniNo.trim().isNotEmpty) ? mniNo.trim() : null,
      'label': (label != null && label.trim().isNotEmpty) ? label.trim() : null,
      'sort_order': sortOrder,
    };
    if (body['booking_no'] == null &&
        body['mni_no'] == null &&
        body['label'] == null) {
      throw const DatabaseException(
          'A person must have a booking #, MNI #, or label.');
    }
    try {
      final Map<String, dynamic> row = await _client
          .from('incident_persons')
          .insert(body)
          .select()
          .single();
      return IncidentPerson.fromJson(row);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to add person', e);
      }
      throw DatabaseException('Failed to add person: $e');
    }
  }

  Future<void> deletePerson(String personId) async {
    try {
      await _client.from('incident_persons').delete().eq('id', personId);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to remove person', e);
      }
      throw DatabaseException('Failed to remove person: $e');
    }
  }

  // ============================================================
  // Attachments
  // ============================================================
  Future<IncidentAttachment> addUrlAttachment({
    required String incidentId,
    required String url,
    required String title,
    required String displayType,
    int sortOrder = 0,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(AppConfig.incidentAttachmentsTable)
          .insert(<String, dynamic>{
            'incident_id': incidentId,
            'kind': 'url',
            'url': url,
            'title': title,
            'display_type': displayType,
            'sort_order': sortOrder,
          })
          .select()
          .single();
      return IncidentAttachment.fromJson(row);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to add link', e);
      }
      throw DatabaseException('Failed to add link: $e');
    }
  }

  /// Uploads bytes to the `incident-media` bucket and records the attachment.
  /// The bucket is public, so we resolve to the public URL for storage.
  Future<IncidentAttachment> uploadFileAttachment({
    required String incidentId,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    required String title,
    required String displayType,
    int sortOrder = 0,
  }) async {
    final String bucketPath =
        '$incidentId/${DateTime.now().millisecondsSinceEpoch}_$filename';

    try {
      await _client.storage.from(AppConfig.incidentMediaBucket).uploadBinary(
            bucketPath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );

      final String publicUrl = _client.storage
          .from(AppConfig.incidentMediaBucket)
          .getPublicUrl(bucketPath);

      final Map<String, dynamic> row = await _client
          .from(AppConfig.incidentAttachmentsTable)
          .insert(<String, dynamic>{
            'incident_id': incidentId,
            'kind': 'file',
            'url': publicUrl,
            'bucket_path': bucketPath,
            'mime_type': mimeType,
            'file_size': bytes.lengthInBytes,
            'title': title,
            'display_type': displayType,
            'sort_order': sortOrder,
          })
          .select()
          .single();

      return IncidentAttachment.fromJson(row);
    } catch (e) {
      debugPrint('[Incidents] Upload failed: $e');
      if (e is StorageException) {
        throw DatabaseException('File upload failed: ${e.message}');
      }
      throw DatabaseException('File upload failed: $e');
    }
  }

  /// Convenience for File path on iOS/Android. Reads bytes then calls
  /// [uploadFileAttachment].
  Future<IncidentAttachment> uploadFileFromPath({
    required String incidentId,
    required String filePath,
    required String mimeType,
    required String title,
    required String displayType,
    int sortOrder = 0,
  }) async {
    final File f = File(filePath);
    final Uint8List bytes = await f.readAsBytes();
    final String filename = filePath.split('/').last;
    return uploadFileAttachment(
      incidentId: incidentId,
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
      title: title,
      displayType: displayType,
      sortOrder: sortOrder,
    );
  }

  /// Edit an existing attachment's user-facing fields. Title and display_type
  /// are always updated; the URL is updated only when [url] is provided
  /// (and only makes sense for kind='url' attachments — file URLs point at
  /// the immutable bucket path).
  Future<IncidentAttachment> updateAttachmentMeta({
    required String attachmentId,
    required String title,
    required String displayType,
    String? url,
  }) async {
    final Map<String, dynamic> patch = <String, dynamic>{
      'title': title,
      'display_type': displayType,
    };
    if (url != null) patch['url'] = url;
    try {
      final Map<String, dynamic> row = await _client
          .from(AppConfig.incidentAttachmentsTable)
          .update(patch)
          .eq('id', attachmentId)
          .select()
          .single();
      return IncidentAttachment.fromJson(row);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to update attachment', e);
      }
      throw DatabaseException('Failed to update attachment: $e');
    }
  }

  Future<void> deleteAttachment(IncidentAttachment att) async {
    try {
      // Best-effort: remove storage file first (only for kind=file)
      if (att.kind == IncidentAttachmentKind.file && att.bucketPath != null) {
        try {
          await _client.storage
              .from(AppConfig.incidentMediaBucket)
              .remove(<String>[att.bucketPath!]);
        } catch (e) {
          debugPrint('[Incidents] Storage remove failed (continuing): $e');
        }
      }
      await _client
          .from(AppConfig.incidentAttachmentsTable)
          .delete()
          .eq('id', att.id);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to delete attachment', e);
      }
      throw DatabaseException('Failed to delete attachment: $e');
    }
  }

  /// Asks the DB whether the *current* signed-in user is an admin or
  /// elevated. Returns false if not signed in.
  Future<bool> currentUserCanEdit() async {
    if (_client.auth.currentUser == null) return false;
    try {
      final dynamic result = await _client.rpc('is_elevated_or_admin');
      return result == true;
    } catch (e) {
      debugPrint('[Incidents] is_elevated_or_admin RPC failed: $e');
      return false;
    }
  }
}

String _yyyymmdd(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
