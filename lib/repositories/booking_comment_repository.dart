import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/booking.dart';
import '../models/booking_comment.dart';

/// Abstract repository for booking comments
abstract class BookingCommentRepository {
  Future<List<BookingComment>> getCommentsByMni(String mniNo);
  Future<List<BookingComment>> getCommentsByName(String personName);
  Future<BookingComment> submitComment({
    required JailBooking booking,
    required String comment,
  });
  Future<BookingComment> editComment({
    required BookingComment currentComment,
    required String updatedComment,
  });
  Future<BookingComment> unpublishComment({
    required BookingComment currentComment,
  });
  Future<void> reportComment({
    required BookingComment comment,
    required String reason,
  });
}

/// Supabase implementation
class SupabaseBookingCommentRepository implements BookingCommentRepository {
  SupabaseBookingCommentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<BookingComment>> getCommentsByMni(String mniNo) async {
    return _getComments(filterColumn: 'mni_no', filterValue: mniNo);
  }

  @override
  Future<List<BookingComment>> getCommentsByName(String personName) async {
    return _getComments(filterColumn: 'person_name', filterValue: personName);
  }

  Future<List<BookingComment>> _getComments({
    required String filterColumn,
    required String filterValue,
  }) async {
    try {
      final List<dynamic> rows =
          await _client
                  .from('booking_comments_latest')
                  .select('*')
                  .eq(filterColumn, filterValue)
                  .order('created_at', ascending: false)
                  .timeout(const Duration(seconds: 10))
              as List<dynamic>;

      if (rows.isEmpty) return <BookingComment>[];

      final userIds = rows
          .map((r) => (r as Map<String, dynamic>)['user_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> userProfiles = {};

      if (userIds.isNotEmpty) {
        try {
          final profiles = await _client
              .from('user_profiles')
              .select('id, display_name, avatar_url, app_user_id, comment_anonymous')
              .inFilter('id', userIds);
          for (final profile in profiles) {
            final p = profile;
            userProfiles[p['id'] as String] = p;
          }
        } catch (e) {
          debugPrint('⚠️ Failed to fetch user profiles: $e');
        }
      }

      return rows.map((dynamic r) {
        final data = r as Map<String, dynamic>;
        final comment = BookingComment.fromJson(data);
        final profile = userProfiles[comment.userId];
        if (profile == null) return comment;
        final bool isAnonymous = profile['comment_anonymous'] as bool? ?? false;
        final String? appUserId = profile['app_user_id'] as String?;
        return comment.copyWith(
          userName: isAnonymous
              ? 'ANON'
              : (appUserId ?? profile['display_name'] as String?),
          userPhotoUrl: isAnonymous ? null : profile['avatar_url'] as String?,
        );
      }).toList();
    } catch (e) {
      throw DatabaseException('Failed to load comments: $e');
    }
  }

  @override
  Future<BookingComment> submitComment({
    required JailBooking booking,
    required String comment,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthenticationException('User not authenticated');
      }
      final profile = await _client
          .from('user_profiles')
          .select('app_user_id')
          .eq('id', userId)
          .maybeSingle();

      final Map<String, dynamic> payload = <String, dynamic>{
        'booking_no': booking.bookingNo,
        'mni_no': booking.mniNo.isNotEmpty ? booking.mniNo : null,
        'person_name': booking.name,
        'booking_date': booking.bookingDate.toUtc().toIso8601String(),
        'user_id': userId,
        'app_user_id': profile?['app_user_id'] as String?,
        'comment': comment,
      };

      final List<dynamic> response =
          await _client
                  .from('booking_comments')
                  .insert(payload)
                  .select()
                  .timeout(const Duration(seconds: 10))
              as List<dynamic>;

      if (response.isEmpty) {
        throw const DatabaseException('Failed to submit comment');
      }

      return BookingComment.fromJson(response.first as Map<String, dynamic>);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to submit comment: $e');
    }
  }

  @override
  Future<BookingComment> editComment({
    required BookingComment currentComment,
    required String updatedComment,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthenticationException('User not authenticated');
      }
      if (userId != currentComment.userId) {
        throw const AuthenticationException('User not authorized to edit');
      }

      final Map<String, dynamic> payload = <String, dynamic>{
        'booking_no': currentComment.bookingNo,
        'mni_no': currentComment.mniNo,
        'person_name': currentComment.personName,
        'booking_date': currentComment.bookingDate?.toUtc().toIso8601String(),
        'user_id': userId,
        'app_user_id': currentComment.appUserId,
        'comment': updatedComment,
        'root_comment_id': currentComment.rootCommentId,
        'parent_comment_id': currentComment.id,
        'is_published': true,
      };

      final List<dynamic> response =
          await _client
                  .from('booking_comments')
                  .insert(payload)
                  .select()
                  .timeout(const Duration(seconds: 10))
              as List<dynamic>;

      if (response.isEmpty) {
        throw const DatabaseException('Failed to update comment');
      }

      return BookingComment.fromJson(response.first as Map<String, dynamic>);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to update comment: $e');
    }
  }

  @override
  Future<BookingComment> unpublishComment({
    required BookingComment currentComment,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthenticationException('User not authenticated');
      }
      if (userId != currentComment.userId) {
        throw const AuthenticationException('User not authorized to unpublish');
      }

      final Map<String, dynamic> payload = <String, dynamic>{
        'booking_no': currentComment.bookingNo,
        'mni_no': currentComment.mniNo,
        'person_name': currentComment.personName,
        'booking_date': currentComment.bookingDate?.toUtc().toIso8601String(),
        'user_id': userId,
        'app_user_id': currentComment.appUserId,
        'comment': currentComment.comment,
        'root_comment_id': currentComment.rootCommentId,
        'parent_comment_id': currentComment.id,
        'is_published': false,
      };

      final List<dynamic> response =
          await _client
                  .from('booking_comments')
                  .insert(payload)
                  .select()
                  .timeout(const Duration(seconds: 10))
              as List<dynamic>;

      if (response.isEmpty) {
        throw const DatabaseException('Failed to unpublish comment');
      }

      return BookingComment.fromJson(response.first as Map<String, dynamic>);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to unpublish comment: $e');
    }
  }

  @override
  Future<void> reportComment({
    required BookingComment comment,
    required String reason,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthenticationException('User not authenticated');
      }

      await _client.rpc(
        'report_booking_comment',
        params: <String, dynamic>{
          'p_comment_id': comment.id,
          'p_reason': reason,
        },
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to report comment: $e');
    }
  }
}
