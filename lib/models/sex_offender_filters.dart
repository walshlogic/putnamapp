/// Filter and sort options for sex offender queries
class SexOffenderFilters {
  SexOffenderFilters({
    this.searchQuery = '',
    this.selectedCity,
    this.sortBy = SortField.name,
    this.sortDirection = SortDirection.ascending,
  });

  final String searchQuery;
  final String? selectedCity; // null means "All Cities"
  final SortField sortBy;
  final SortDirection sortDirection;

  /// Check if any filters are active
  bool get hasActiveFilters => searchQuery.isNotEmpty || selectedCity != null;

  /// Create a copy with updated values
  SexOffenderFilters copyWith({
    String? searchQuery,
    String? selectedCity,
    SortField? sortBy,
    SortDirection? sortDirection,
  }) {
    return SexOffenderFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCity: selectedCity ?? this.selectedCity,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }
}

/// Sort fields for sex offenders
enum SortField {
  name,
  city,
  age,
  none,
}

/// Sort direction
enum SortDirection {
  ascending,
  descending,
}

