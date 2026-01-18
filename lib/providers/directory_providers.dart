import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';
import '../models/place_filters.dart';
import '../repositories/directory_repository.dart';

/// Provider for DirectoryRepository
final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
  return SupabaseDirectoryRepository(Supabase.instance.client);
});

/// Provider for all places
final allPlacesProvider = FutureProvider<List<Place>>((ref) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getPlaces();
});

/// Provider for places by category
final placesByCategoryProvider =
    FutureProvider.family<List<Place>, String>((ref, category) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getPlacesByCategory(category);
});

/// Provider for filtered places
final filteredPlacesProvider =
    FutureProvider.family<List<Place>, PlaceFilters>((ref, filters) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getFilteredPlaces(filters);
});

/// Provider for subcategories in a category
final subcategoriesProvider =
    FutureProvider.family<List<String>, String>((ref, category) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getSubcategories(category);
});

/// Provider for search results
final searchPlacesProvider =
    FutureProvider.family<List<Place>, String>((ref, query) async {
  if (query.isEmpty) return <Place>[];
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.searchPlaces(query);
});

/// Provider for single place details
final placeDetailProvider =
    FutureProvider.family<Place, String>((ref, placeId) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getPlaceById(placeId);
});

/// Provider for user favorites
final userFavoritesProvider =
    FutureProvider.family<List<Place>, String>((ref, userId) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getUserFavorites(userId);
});

/// Provider to check if place is favorited
final isPlaceFavoritedProvider =
    FutureProvider.family<bool, ({String userId, String placeId})>(
  (ref, params) async {
    final repository = ref.watch(directoryRepositoryProvider);
    return repository.isFavorited(params.userId, params.placeId);
  },
);

/// State notifier provider for adding/removing favorites
final toggleFavoriteProvider =
    Provider<Future<void> Function(String userId, String placeId, bool isFavorited)>(
  (ref) => (userId, placeId, isFavorited) async {
    final repository = ref.read(directoryRepositoryProvider);
    
    if (isFavorited) {
      await repository.removeFavorite(userId, placeId);
    } else {
      await repository.addFavorite(userId, placeId);
    }
    
    // Invalidate relevant providers
    ref.invalidate(userFavoritesProvider);
    ref.invalidate(isPlaceFavoritedProvider);
  },
);

