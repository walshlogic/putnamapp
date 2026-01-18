import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/review.dart';
import '../repositories/review_repository.dart';

/// Provider for ReviewRepository
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return SupabaseReviewRepository(Supabase.instance.client);
});

/// Provider for fetching reviews for a specific place
final placeReviewsProvider = FutureProvider.family<List<Review>, String>(
  (ref, placeId) async {
    final repository = ref.watch(reviewRepositoryProvider);
    return repository.getPlaceReviews(placeId);
  },
);

/// Provider for checking if current user has reviewed a place
final userReviewForPlaceProvider = FutureProvider.family<Review?, String>(
  (ref, placeId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    if (userId == null) return null;
    
    final repository = ref.watch(reviewRepositoryProvider);
    return repository.getUserReviewForPlace(placeId, userId);
  },
);

/// State notifier for review submission
class ReviewSubmissionNotifier extends Notifier<AsyncValue<Review?>> {
  @override
  AsyncValue<Review?> build() {
    return const AsyncValue.data(null);
  }

  ReviewRepository get _repository => ref.read(reviewRepositoryProvider);

  /// Submit a new review
  Future<void> submitReview({
    required String placeId,
    required int rating,
    required String comment,
    String? title,
    DateTime? visitDate,
    bool isAnonymous = false,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final review = await _repository.submitReview(
        placeId: placeId,
        rating: rating,
        comment: comment,
        title: title,
        visitDate: visitDate,
        isAnonymous: isAnonymous,
      );
      
      state = AsyncValue.data(review);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update an existing review
  Future<void> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    String? title,
    DateTime? visitDate,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final review = await _repository.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
        title: title,
        visitDate: visitDate,
      );
      
      state = AsyncValue.data(review);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for review submission
final reviewSubmissionProvider =
    NotifierProvider<ReviewSubmissionNotifier, AsyncValue<Review?>>(
  ReviewSubmissionNotifier.new,
);

