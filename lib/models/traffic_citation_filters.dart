import '../config/app_config.dart';
import 'traffic_citation.dart';

/// Filters for traffic citation queries
class TrafficCitationFilters {
  const TrafficCitationFilters({
    this.timeRange = AppConfig.timeRangeThisYear,
    this.searchQuery,
    this.city,
    this.violationType,
    this.sortBy = AppConfig.sortByDate,
    this.sortOrder = AppConfig.sortOrderDesc,
    this.nameSortBy = AppConfig.nameSortByLastName,
    this.page = 1,
    this.pageSize = 50,
  });

  /// Time range filter ('1 YEAR', '5 YEARS', 'ALL')
  final String timeRange;

  /// Search query (searches name, license plate, case number)
  final String? searchQuery;

  /// Filter by city
  final String? city;

  /// Filter by violation type (partial match on violation description)
  final String? violationType;

  /// Sort by field ('DATE', 'NAME')
  final String sortBy;

  /// Sort order ('ASC', 'DESC')
  final String sortOrder;

  /// Name sort field ('FIRST_NAME', 'LAST_NAME')
  final String nameSortBy;

  /// Page number (1-indexed)
  final int page;

  /// Number of results per page
  final int pageSize;

  /// Get start date based on time range
  DateTime? get startDate {
    final DateTime now = DateTime.now();
    if (timeRange == AppConfig.timeRangeThisYear) {
      // Calculate 12 months ago from today (past 12 months)
      // Subtract 12 months, handling year boundaries correctly
      return DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 365));
    } else if (timeRange == AppConfig.timeRange5Years) {
      return DateTime(now.year - 5, now.month, now.day);
    }
    return null; // ALL - no start date filter
  }

  /// Get end date (always null - we show up to today)
  DateTime? get endDate => null;

  /// Create filters for recent citations (last 30 days)
  factory TrafficCitationFilters.recent() {
    return TrafficCitationFilters(timeRange: AppConfig.timeRangeThisYear);
  }

  /// Create filters for all citations
  factory TrafficCitationFilters.all() {
    return TrafficCitationFilters(timeRange: AppConfig.timeRangeAll);
  }

  /// Create a copy with updated values
  TrafficCitationFilters copyWith({
    String? timeRange,
    String? searchQuery,
    String? city,
    String? violationType,
    String? sortBy,
    String? sortOrder,
    String? nameSortBy,
    int? page,
    int? pageSize,
  }) {
    return TrafficCitationFilters(
      timeRange: timeRange ?? this.timeRange,
      searchQuery: searchQuery ?? this.searchQuery,
      city: city ?? this.city,
      violationType: violationType ?? this.violationType,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      nameSortBy: nameSortBy ?? this.nameSortBy,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Check if any filters are active (beyond default time range)
  bool get hasFilters {
    return (searchQuery != null && searchQuery!.isNotEmpty) ||
        (city != null && city!.isNotEmpty) ||
        (violationType != null && violationType!.isNotEmpty) ||
        timeRange != AppConfig.timeRangeThisYear; // Different from default
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrafficCitationFilters &&
          runtimeType == other.runtimeType &&
          timeRange == other.timeRange &&
          searchQuery == other.searchQuery &&
          city == other.city &&
          violationType == other.violationType &&
          sortBy == other.sortBy &&
          sortOrder == other.sortOrder &&
          nameSortBy == other.nameSortBy &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode =>
      timeRange.hashCode ^
      searchQuery.hashCode ^
      city.hashCode ^
      violationType.hashCode ^
      sortBy.hashCode ^
      sortOrder.hashCode ^
      nameSortBy.hashCode ^
      page.hashCode ^
      pageSize.hashCode;
}

/// Results from a traffic citation query
class TrafficCitationResults {
  TrafficCitationResults({
    required this.citations,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<TrafficCitation> citations;
  final int totalCount;
  final int page;
  final int pageSize;

  /// Total number of pages
  int get totalPages => (totalCount / pageSize).ceil();

  /// Whether there are more pages
  bool get hasMore => page < totalPages;
}
