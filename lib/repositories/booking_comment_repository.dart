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
                  .from('booking_comments')
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
              .select('id, display_name, avatar_url')
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
        return comment.copyWith(
          userName: profile['display_name'] as String?,
          userPhotoUrl: profile['avatar_url'] as String?,
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

      final Map<String, dynamic> payload = <String, dynamic>{
        'booking_no': booking.bookingNo,
        'mni_no': booking.mniNo.isNotEmpty ? booking.mniNo : null,
        'person_name': booking.name,
        'booking_date': booking.bookingDate.toUtc().toIso8601String(),
        'user_id': userId,
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
}
