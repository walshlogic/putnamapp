import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/place.dart';
import '../models/place_filters.dart';
import '../models/place_review.dart';

/// Abstract repository for directory operations
abstract class DirectoryRepository {
  /// Get all places, optionally filtered by category
  Future<List<Place>> getPlaces({String? category, String? searchQuery});

  /// Get filtered places
  Future<List<Place>> getFilteredPlaces(PlaceFilters filters);

  /// Get a single place by ID
  Future<Place> getPlaceById(String id);

  /// Get places by category
  Future<List<Place>> getPlacesByCategory(String category);

  /// Search places by name or description
  Future<List<Place>> searchPlaces(String query);
  
  /// Get available subcategories for a category
  Future<List<String>> getSubcategories(String category);

  /// Get reviews for a place
  Future<List<PlaceReview>> getPlaceReviews(String placeId);

  /// Increment view count
  Future<void> incrementViewCount(String placeId);

  /// Get user's favorite places
  Future<List<Place>> getUserFavorites(String userId);

  /// Add place to favorites
  Future<void> addFavorite(String userId, String placeId);

  /// Remove place from favorites
  Future<void> removeFavorite(String userId, String placeId);

  /// Check if place is favorited by user
  Future<bool> isFavorited(String userId, String placeId);
}

/// Supabase implementation of DirectoryRepository
class SupabaseDirectoryRepository implements DirectoryRepository {
  SupabaseDirectoryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Place>> getPlaces({
    String? category,
    String? searchQuery,
  }) async {
    try {
      dynamic query = _client
          .from('places')
          .select('''
            *,
            review_count:place_reviews(count),
            average_rating:place_reviews(rating)
          ''')
          .eq('is_active', true);

      // Filter by category (case-insensitive)
      if (category != null && category.isNotEmpty) {
        query = query.ilike('category', category);
      }

      // Search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchPattern = '%$searchQuery%';
        query = query.or('name.ilike.$searchPattern,description.ilike.$searchPattern');
      }

      // Order by rating and view count
      query = query.order('view_count', ascending: false);

      final List<dynamic> rows = await query as List<dynamic>;

      return rows.map((row) {
        // Calculate average rating from reviews
        final reviewsData = row['place_reviews'] as List?;
        int reviewCount = 0;
        double avgRating = 0.0;

        if (reviewsData != null && reviewsData.isNotEmpty) {
          reviewCount = reviewsData.length;
          final ratings = reviewsData
              .map((r) => (r['rating'] as num?)?.toDouble() ?? 0.0)
              .toList();
          if (ratings.isNotEmpty) {
            avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
          }
        }

        final placeData = Map<String, dynamic>.from(row as Map);
        placeData['review_count'] = reviewCount;
        placeData['average_rating'] = avgRating;

        return Place.fromJson(placeData);
      }).toList();
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch places', e);
      }
      throw DatabaseException('Failed to load places: $e');
    }
  }

  @override
  Future<Place> getPlaceById(String id) async {
    try {
      final response = await _client
          .from('places')
          .select('''
            *,
            review_count:place_reviews(count),
            average_rating:place_reviews(rating)
          ''')
          .eq('id', id)
          .eq('is_active', true)
          .single();

      // Calculate average rating
      final reviewsData = response['place_reviews'] as List?;
      int reviewCount = 0;
      double avgRating = 0.0;

      if (reviewsData != null && reviewsData.isNotEmpty) {
        reviewCount = reviewsData.length;
        final ratings = reviewsData
            .map((r) => (r['rating'] as num?)?.toDouble() ?? 0.0)
            .toList();
        if (ratings.isNotEmpty) {
          avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
        }
      }

      final placeData = Map<String, dynamic>.from(response);
      placeData['review_count'] = reviewCount;
      placeData['average_rating'] = avgRating;

      return Place.fromJson(placeData);
    } catch (e) {
      if (e is PostgrestException) {
        throw NotFoundException('Place not found');
      }
      throw DatabaseException('Failed to load place: $e');
    }
  }

  @override
  Future<List<Place>> getPlacesByCategory(String category) async {
    return getPlaces(category: category);
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    return getPlaces(searchQuery: query);
  }

  @override
  Future<List<Place>> getFilteredPlaces(PlaceFilters filters) async {
    try {
      dynamic query = _client.from('places').select().eq('is_active', true);

      // Category filter
      if (filters.category != null && filters.category!.isNotEmpty) {
        query = query.ilike('category', filters.category!);
      }

      // Subcategory filter (multiple)
      if (filters.subcategories.isNotEmpty) {
        final subcategoryConditions = filters.subcategories
            .map((sub) => 'subcategory.ilike.%$sub%')
            .join(',');
        query = query.or(subcategoryConditions);
      }

      // Price range filter (multiple)
      if (filters.priceRanges.isNotEmpty) {
        final priceConditions = filters.priceRanges
            .map((price) => 'price_range.eq.$price')
            .join(',');
        query = query.or(priceConditions);
      }

      // Search query
      if (filters.searchQuery.isNotEmpty) {
        final searchPattern = '%${filters.searchQuery}%';
        query = query.or('name.ilike.$searchPattern,description.ilike.$searchPattern');
      }

      // Min rating filter
      if (filters.minRating > 0) {
        query = query.gte('average_rating', filters.minRating);
      }

      // Verified only filter
      if (filters.onlyVerified) {
        query = query.eq('is_verified', true);
      }

      // Sorting
      final bool ascending = filters.sortDirection == PlaceSortDirection.ascending;
      switch (filters.sortBy) {
        case PlaceSortField.name:
          query = query.order('name', ascending: ascending);
          break;
        case PlaceSortField.rating:
          query = query.order('average_rating', ascending: ascending);
          break;
        case PlaceSortField.reviewCount:
          query = query.order('review_count', ascending: ascending);
          break;
        case PlaceSortField.priceRange:
          query = query.order('price_range', ascending: ascending);
          break;
      }

      final List<dynamic> rows = await query as List<dynamic>;

      return rows.map((row) {
        final placeData = Map<String, dynamic>.from(row as Map);
        return Place.fromJson(placeData);
      }).toList();
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch filtered places', e);
      }
      throw DatabaseException('Failed to load filtered places: $e');
    }
  }

  @override
  Future<List<String>> getSubcategories(String category) async {
    try {
      final rows = await _client
          .from('places')
          .select('subcategory')
          .eq('is_active', true)
          .ilike('category', category)
          .not('subcategory', 'is', null);

      final Set<String> subcategories = <String>{};
      for (final row in rows as List) {
        final subcategory = row['subcategory'] as String?;
        if (subcategory != null && subcategory.isNotEmpty) {
          subcategories.add(subcategory);
        }
      }

      return subcategories.toList()..sort();
    } catch (e) {
      // Return empty list on error
      return <String>[];
    }
  }

  @override
  Future<List<PlaceReview>> getPlaceReviews(String placeId) async {
    try {
      final rows = await _client
          .from('place_reviews')
          .select('''
            *,
            user_profiles!inner(
              display_name,
              avatar_url
            )
          ''')
          .eq('place_id', placeId)
          .eq('is_approved', true)
          .order('created_at', ascending: false);

      return (rows as List).map((row) {
        final userData = row['user_profiles'] as Map?;
        final reviewData = Map<String, dynamic>.from(row);
        reviewData['user_name'] = userData?['display_name'];
        reviewData['user_photo_url'] = userData?['avatar_url'];
        return PlaceReview.fromJson(reviewData);
      }).toList();
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch reviews', e);
      }
      throw DatabaseException('Failed to load reviews: $e');
    }
  }

  @override
  Future<void> incrementViewCount(String placeId) async {
    try {
      await _client.rpc('increment_place_views', params: {
        'place_id_param': placeId,
      });
    } catch (e) {
      // Don't throw - view count is not critical
      debugPrint('Failed to increment view count: $e');
    }
  }

  @override
  Future<List<Place>> getUserFavorites(String userId) async {
    try {
      final rows = await _client
          .from('user_favorites')
          .select('''
            place_id,
            places!inner(
              *,
              review_count:place_reviews(count),
              average_rating:place_reviews(rating)
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (rows as List).map((row) {
        final placeData = row['places'] as Map;
        
        // Calculate average rating
        final reviewsData = placeData['place_reviews'] as List?;
        int reviewCount = 0;
        double avgRating = 0.0;

        if (reviewsData != null && reviewsData.isNotEmpty) {
          reviewCount = reviewsData.length;
          final ratings = reviewsData
              .map((r) => (r['rating'] as num?)?.toDouble() ?? 0.0)
              .toList();
          if (ratings.isNotEmpty) {
            avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
          }
        }

        final placeMap = Map<String, dynamic>.from(placeData);
        placeMap['review_count'] = reviewCount;
        placeMap['average_rating'] = avgRating;

        return Place.fromJson(placeMap);
      }).toList();
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch favorites', e);
      }
      throw DatabaseException('Failed to load favorites: $e');
    }
  }

  @override
  Future<void> addFavorite(String userId, String placeId) async {
    try {
      await _client.from('user_favorites').insert({
        'user_id': userId,
        'place_id': placeId,
      });
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to add favorite', e);
      }
      throw DatabaseException('Failed to add favorite: $e');
    }
  }

  @override
  Future<void> removeFavorite(String userId, String placeId) async {
    try {
      await _client
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('place_id', placeId);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to remove favorite', e);
      }
      throw DatabaseException('Failed to remove favorite: $e');
    }
  }

  @override
  Future<bool> isFavorited(String userId, String placeId) async {
    try {
      final rows = await _client
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('place_id', placeId)
          .limit(1);

      return (rows as List).isNotEmpty;
    } catch (e) {
      return false; // Default to not favorited on error
    }
  }
}

