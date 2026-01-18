import '../config/app_config.dart';
import 'booking.dart';

/// Sort field options
enum SortField {
  none,
  name,
  date,
  charges,
}

/// Sort direction
enum SortDirection {
  ascending,
  descending,
}

/// Filter configuration for booking queries
class BookingFilters {
  const BookingFilters({
    this.timeRange = AppConfig.timeRange24Hours,
    this.status = 'All',
    this.searchQuery = '',
    this.sortBy = SortField.none,
    this.sortDirection = SortDirection.ascending,
    this.offset = 0,
    this.limit = AppConfig.defaultPageSize,
  });

  final String timeRange; // '24HR', '12MONTH', '5YEAR', 'ALL'
  final String status; // 'All', 'In Jail', 'Released'
  final String searchQuery;
  final SortField sortBy;
  final SortDirection sortDirection;
  final int offset;
  final int limit;

  BookingFilters copyWith({
    String? timeRange,
    String? status,
    String? searchQuery,
    SortField? sortBy,
    SortDirection? sortDirection,
    int? offset,
    int? limit,
  }) {
    return BookingFilters(
      timeRange: timeRange ?? this.timeRange,
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingFilters &&
          runtimeType == other.runtimeType &&
          timeRange == other.timeRange &&
          status == other.status &&
          searchQuery == other.searchQuery &&
          sortBy == other.sortBy &&
          sortDirection == other.sortDirection &&
          offset == other.offset &&
          limit == other.limit;

  @override
  int get hashCode =>
      timeRange.hashCode ^
      status.hashCode ^
      searchQuery.hashCode ^
      sortBy.hashCode ^
      sortDirection.hashCode ^
      offset.hashCode ^
      limit.hashCode;
}

/// Results with pagination info
class BookingResults {
  const BookingResults({
    required this.bookings,
    required this.hasMore,
    required this.totalCount,
  });

  final List<JailBooking> bookings;
  final bool hasMore;
  final int totalCount;
}

