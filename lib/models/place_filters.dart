/// Filter and sort options for places
class PlaceFilters {
  PlaceFilters({
    this.category,
    this.subcategories = const <String>[],
    this.priceRanges = const <String>[],
    this.searchQuery = '',
    this.sortBy = PlaceSortField.rating,
    this.sortDirection = PlaceSortDirection.descending,
    this.minRating = 0.0,
    this.onlyVerified = false,
  });

  final String? category;
  final List<String> subcategories;
  final List<String> priceRanges; // '$', '$$', '$$$'
  final String searchQuery;
  final PlaceSortField sortBy;
  final PlaceSortDirection sortDirection;
  final double minRating;
  final bool onlyVerified;

  /// Copy with new values
  PlaceFilters copyWith({
    String? category,
    List<String>? subcategories,
    List<String>? priceRanges,
    String? searchQuery,
    PlaceSortField? sortBy,
    PlaceSortDirection? sortDirection,
    double? minRating,
    bool? onlyVerified,
  }) {
    return PlaceFilters(
      category: category ?? this.category,
      subcategories: subcategories ?? this.subcategories,
      priceRanges: priceRanges ?? this.priceRanges,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      minRating: minRating ?? this.minRating,
      onlyVerified: onlyVerified ?? this.onlyVerified,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceFilters &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          _listEquals(subcategories, other.subcategories) &&
          _listEquals(priceRanges, other.priceRanges) &&
          searchQuery == other.searchQuery &&
          sortBy == other.sortBy &&
          sortDirection == other.sortDirection &&
          minRating == other.minRating &&
          onlyVerified == other.onlyVerified;

  @override
  int get hashCode =>
      category.hashCode ^
      Object.hashAll(subcategories) ^
      Object.hashAll(priceRanges) ^
      searchQuery.hashCode ^
      sortBy.hashCode ^
      sortDirection.hashCode ^
      minRating.hashCode ^
      onlyVerified.hashCode;

  /// Helper to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// Sort field options for places
enum PlaceSortField {
  name,
  rating,
  reviewCount,
  priceRange,
}

/// Sort direction
enum PlaceSortDirection {
  ascending,
  descending,
}

/// Extension for display labels
extension PlaceSortFieldX on PlaceSortField {
  String get label {
    switch (this) {
      case PlaceSortField.name:
        return 'NAME';
      case PlaceSortField.rating:
        return 'RATING';
      case PlaceSortField.reviewCount:
        return 'REVIEWS';
      case PlaceSortField.priceRange:
        return 'PRICE';
    }
  }
}

