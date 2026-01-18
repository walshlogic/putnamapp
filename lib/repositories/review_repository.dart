import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/review.dart';

/// Abstract repository for review data operations
abstract class ReviewRepository {
  /// Get reviews for a specific place
  Future<List<Review>> getPlaceReviews(String placeId);

  /// Submit a new review
  Future<Review> submitReview({
    required String placeId,
    required int rating,
    required String comment,
    String? title,
    DateTime? visitDate,
    bool isAnonymous = false,
  });

  /// Update an existing review
  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    String? title,
    DateTime? visitDate,
  });

  /// Check if user has already reviewed a place
  Future<Review?> getUserReviewForPlace(String placeId, String userId);
}

/// Supabase implementation of ReviewRepository
class SupabaseReviewRepository implements ReviewRepository {
  SupabaseReviewRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Review>> getPlaceReviews(String placeId) async {
    try {
      // Use raw SQL-style query to ensure LEFT JOIN works
      final response = await _client
          .rpc('get_place_reviews', params: {'p_place_id': placeId})
          .timeout(const Duration(seconds: 10));

      if (response == null) return <Review>[];

      final List<dynamic> rows = response as List<dynamic>;

      return rows.map((dynamic r) {
        final data = r as Map<String, dynamic>;
        return Review.fromJson(data);
      }).toList();
    } catch (e) {
      // If RPC fails, fall back to simple query
      try {
        final List<dynamic> rows =
            await _client
                    .from('place_reviews')
                    .select('*')
                    .eq('place_id', placeId)
                    .eq('is_approved', true)
                    .order('created_at', ascending: false)
                    .timeout(const Duration(seconds: 10))
                as List<dynamic>;

        // Fetch all user profiles in one query
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
          final userId = data['user_id'] as String?;
          final profile = userId != null ? userProfiles[userId] : null;

          return Review.fromJson(<String, dynamic>{
            ...data,
            'user_name': profile?['display_name'] ?? 'Anonymous',
            'user_photo_url': profile?['avatar_url'],
          });
        }).toList();
      } catch (fallbackError) {
        if (fallbackError is PostgrestException) {
          throw DatabaseException('Failed to fetch reviews', fallbackError);
        }
        throw DatabaseException('Failed to load reviews: $fallbackError');
      }
    }
  }

  @override
  Future<Review> submitReview({
    required String placeId,
    required int rating,
    required String comment,
    String? title,
    DateTime? visitDate,
    bool isAnonymous = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthenticationException('User not authenticated');
      }

      final Map<String, dynamic> reviewData = <String, dynamic>{
        'place_id': placeId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
        'title': title,
        'visit_date': visitDate?.toIso8601String(),
        'is_anonymous': isAnonymous,
        'is_approved': false, // Requires admin approval
      };

      final List<dynamic> response =
          await _client
                  .from('place_reviews')
                  .insert(reviewData)
                  .select()
                  .timeout(const Duration(seconds: 10))
              as List<dynamic>;

      if (response.isEmpty) {
        throw const DatabaseException('Failed to submit review');
      }

      return Review.fromJson(response.first as Map<String, dynamic>);
    } catch (e) {
      if (e is PostgrestException) {
        if (e.code == '23505') {
          // Unique constraint violation - user already reviewed
          throw const DatabaseException('You have already reviewed this place');
        }
        throw DatabaseException('Failed to submit review', e);
      }
      throw DatabaseException('Failed to submit review: $e');
    }
  }

  @override
  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    String? title,
    DateTime? visitDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthenticationException('User not authenticated');
      }

      final Map<String, dynamic> updateData = <String, dynamic>{
        'rating': rating,
        'comment': comment,
        'title': title,
        'visit_date': visitDate?.toIso8601String(),
        'is_approved': false, // Requires re-approval after edit
      };

      final List<dynamic> response =
          await _client
                  .from('place_reviews')
                  .update(updateData)
                  .eq('id', reviewId)
                  .eq('user_id', userId) // Ensure user owns this review
                  .select()
                  .timeout(const Duration(seconds: 10))
              as List<dynamic>;

      if (response.isEmpty) {
        throw const DatabaseException('Review not found or unauthorized');
      }

      return Review.fromJson(response.first as Map<String, dynamic>);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to update review', e);
      }
      throw DatabaseException('Failed to update review: $e');
    }
  }

  @override
  Future<Review?> getUserReviewForPlace(String placeId, String userId) async {
    try {
      final List<dynamic> rows =
          await _client
                  .from('place_reviews')
                  .select()
                  .eq('place_id', placeId)
                  .eq('user_id', userId)
                  .limit(1)
                  .timeout(const Duration(seconds: 10))
              as List<dynamic>;

      if (rows.isEmpty) return null;

      return Review.fromJson(rows.first as Map<String, dynamic>);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to check existing review', e);
      }
      throw DatabaseException('Failed to check existing review: $e');
    }
  }
}
