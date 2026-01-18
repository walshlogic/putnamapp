import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../exceptions/app_exceptions.dart';
import '../models/booking.dart';
import '../models/booking_filters.dart';
import '../utils/booking_parser.dart';

/// Represents a person charged with a specific charge
class PersonWithCharge {
  PersonWithCharge({
    required this.name,
    required this.bookingDate,
    required this.count,
  });

  final String name;
  final DateTime bookingDate;
  final int count; // Number of times charged with this specific charge
}

/// Abstract repository for booking data operations
abstract class BookingRepository {
  /// Get bookings with filters and pagination
  Future<BookingResults> getBookings(BookingFilters filters);

  /// Get bookings by name
  Future<List<JailBooking>> getBookingsByName(String name);

  /// Get bookings by MNI number (more reliable for history grouping)
  Future<List<JailBooking>> getBookingsByMni(String mniNo);

  /// Get pre-calculated booking count for a specific filter combination
  Future<int> getBookingCount(String statKey);

  /// Get people charged with a specific charge (within time range)
  Future<List<PersonWithCharge>> getPeopleByCharge(
    String chargeName,
    String timeRange,
  );

  /// Get bookings for a specific date
  Future<List<JailBooking>> getBookingsByDate(DateTime date);
}

/// Supabase implementation of BookingRepository
class SupabaseBookingRepository implements BookingRepository {
  SupabaseBookingRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<BookingResults> getBookings(BookingFilters filters) async {
    try {
      final DateTime now = DateTime.now();
      int totalCount = 0;

      // STEP 1: Get EXACT total count
      if (filters.searchQuery.isEmpty) {
        // For 24HRS, always count on-the-fly (stats can be stale)
        // For THISYEAR and 5YEARS, count on-the-fly (stats may not exist yet)
        if (filters.timeRange == AppConfig.timeRange24Hours ||
            filters.timeRange == AppConfig.timeRangeThisYear ||
            filters.timeRange == AppConfig.timeRange5Years) {
          totalCount = await _countBookingsWithSearch(filters, now);
        } else {
          // For ALL, use pre-calculated stats from booking_stats table
          final String statKey = _buildStatKey(filters);
          final List<dynamic> statRows = await _client
              .from(AppConfig.bookingStatsTable)
              .select('count')
              .eq('stat_key', statKey)
              .limit(1)
              .timeout(AppConfig.shortTimeout) as List<dynamic>;

          if (statRows.isNotEmpty) {
            totalCount = statRows.first['count'] as int? ?? 0;
          } else {
            // If stat doesn't exist, count on-the-fly as fallback
            totalCount = await _countBookingsWithSearch(filters, now);
          }
        }
      } else {
        // For search queries, count on-the-fly
        totalCount = await _countBookingsWithSearch(filters, now);
      }

      // STEP 2: Build data query for actual bookings
      dynamic query = _client.from(AppConfig.bookingsTable).select('*');

      // Apply time filter
      query = _applyTimeFilter(query, filters.timeRange, now);

      // Apply status filter
      query = _applyStatusFilter(query, filters.status);

      // Apply search filter
      if (filters.searchQuery.isNotEmpty) {
        final String searchPattern = '%${filters.searchQuery}%';
        query = query.or(
          'name.ilike.$searchPattern,booking_no.ilike.$searchPattern',
        );
      }

      // Apply sorting (only date sorting is done in SQL, others are done in-memory)
      if (filters.sortBy == SortField.date) {
        query = query.order(
          'booking_date',
          ascending: filters.sortDirection == SortDirection.ascending,
        );
      } else {
        // Default: order by most recent
        query = query.order('booking_date', ascending: false);
      }

      // Apply pagination for THISYEAR, 5YEARS, and ALL
      // For 24HRS, fetch all records (no pagination)
      if (filters.timeRange == AppConfig.timeRange24Hours) {
        // For 24HRS, set a high limit to get all records without pagination
        // (typically there are fewer than 100 bookings in 24 hours)
        query = query.limit(1000);
      } else {
        query = query.range(
          filters.offset,
          filters.offset + filters.limit - 1,
        );
      }

      // Execute data query with timeout
      final List<dynamic> rows =
          await query.timeout(AppConfig.longTimeout) as List<dynamic>;

      List<JailBooking> bookings = BookingParser.parseBookingList(rows);

      // Apply in-memory sorting for name and charges
      if (filters.sortBy == SortField.name ||
          filters.sortBy == SortField.charges) {
        bookings = _applySorting(bookings, filters);
      }

      // Determine if there are more results
      final bool hasMore = (filters.offset + bookings.length) < totalCount;

      return BookingResults(
        bookings: bookings,
        hasMore: hasMore,
        totalCount: totalCount,
      );
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch bookings', e);
      }
      throw DatabaseException('Failed to load bookings: $e');
    }
  }

  @override
  Future<List<JailBooking>> getBookingsByName(String name) async {
    try {
      final List<dynamic> rows = await _client
          .from(AppConfig.bookingsTable)
          .select('*')
          .eq('name', name)
          .order('booking_date', ascending: false)
          .limit(50)
          .timeout(AppConfig.defaultTimeout) as List<dynamic>;

      return BookingParser.parseBookingList(rows);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch bookings for $name', e);
      }
      throw DatabaseException('Failed to load bookings for $name: $e');
    }
  }

  @override
  Future<List<JailBooking>> getBookingsByMni(String mniNo) async {
    try {
      final List<dynamic> rows = await _client
          .from(AppConfig.bookingsTable)
          .select('*')
          .eq('mni_no', mniNo)
          .order('booking_date', ascending: false)
          .limit(50)
          .timeout(AppConfig.defaultTimeout) as List<dynamic>;

      return BookingParser.parseBookingList(rows);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch bookings for MNI $mniNo', e);
      }
      throw DatabaseException('Failed to load bookings for MNI $mniNo: $e');
    }
  }

  @override
  Future<int> getBookingCount(String statKey) async {
    try {
      final List<dynamic> statRows = await _client
          .from(AppConfig.bookingStatsTable)
          .select('count')
          .eq('stat_key', statKey)
          .limit(1)
          .timeout(AppConfig.shortTimeout) as List<dynamic>;

      if (statRows.isNotEmpty) {
        return statRows.first['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      throw DatabaseException('Failed to fetch booking count', e);
    }
  }

  /// Build stat key for pre-calculated counts
  String _buildStatKey(BookingFilters filters) {
    String statKey = '';

    // Build stat key based on filters
    if (filters.status == AppConfig.statusInJail) {
      statKey = 'in_jail_';
    } else if (filters.status == AppConfig.statusReleased) {
      statKey = 'released_';
    } else {
      statKey = 'total_';
    }

    // Add time range
    if (filters.timeRange == AppConfig.timeRange24Hours) {
      statKey += '24hrs';
    } else if (filters.timeRange == AppConfig.timeRangeThisYear) {
      statKey += 'thisyear';
    } else if (filters.timeRange == AppConfig.timeRange5Years) {
      statKey += '5years';
    } else {
      statKey += 'all';
    }

    return statKey;
  }

  /// Count bookings with or without search query
  /// Uses batch fetching to work around Supabase's 1000 row limit
  Future<int> _countBookingsWithSearch(
    BookingFilters filters,
    DateTime now,
  ) async {
    int totalCount = 0;
    int offset = 0;
    const int batchSize = 1000;
    bool hasMore = true;

    // Fetch in batches to work around Supabase's 1000 row limit
    while (hasMore) {
      dynamic countQuery = _client
          .from(AppConfig.bookingsTable)
          .select('booking_no');

      // Apply time filter
      countQuery = _applyTimeFilter(countQuery, filters.timeRange, now);

      // Apply status filter
      countQuery = _applyStatusFilter(countQuery, filters.status);

      // Apply search filter only if provided
      if (filters.searchQuery.isNotEmpty) {
        final String searchPattern = '%${filters.searchQuery}%';
        countQuery = countQuery.or(
          'name.ilike.$searchPattern,booking_no.ilike.$searchPattern',
        );
      }

      // Order for consistent results
      countQuery = countQuery.order('booking_date', ascending: false);

      // Fetch a batch using range
      countQuery = countQuery.range(offset, offset + batchSize - 1);

      // Execute count query
      final List<dynamic> batch =
          await countQuery.timeout(AppConfig.defaultTimeout) as List<dynamic>;
      
      totalCount += batch.length;

      // If we got less than a full batch, we're done
      if (batch.length < batchSize) {
        hasMore = false;
      } else {
        offset += batchSize;
      }
    }

    return totalCount;
  }

  /// Apply time filter to query
  dynamic _applyTimeFilter(
    dynamic query,
    String timeRange,
    DateTime now,
  ) {
    if (timeRange == AppConfig.timeRange24Hours) {
      final DateTime cutoff = now.subtract(AppConfig.time24Hours);
      return query.gte('booking_date', cutoff.toIso8601String());
    } else if (timeRange == AppConfig.timeRangeThisYear) {
      final DateTime cutoff = DateTime(now.year, 1, 1);
      return query.gte('booking_date', cutoff.toIso8601String());
    } else if (timeRange == AppConfig.timeRange5Years) {
      final DateTime cutoff = DateTime(now.year - 5, now.month, now.day);
      return query.gte('booking_date', cutoff.toIso8601String());
    }
    // If 'ALL', no time filter
    return query;
  }

  /// Apply status filter to query
  dynamic _applyStatusFilter(dynamic query, String status) {
    if (status == AppConfig.statusInJail) {
      return query.or('status.ilike.%IN JAIL%,status.eq.BOOKED');
    } else if (status == AppConfig.statusReleased) {
      return query.not('released_date', 'is', null);
    }
    // If 'All', no status filter
    return query;
  }

  /// Apply in-memory sorting to bookings list
  List<JailBooking> _applySorting(
    List<JailBooking> bookings,
    BookingFilters filters,
  ) {
    final List<JailBooking> sorted = List<JailBooking>.from(bookings);

    switch (filters.sortBy) {
      case SortField.name:
        sorted.sort((JailBooking a, JailBooking b) {
          // Parse name format: "LASTNAME, FIRSTNAME MIDDLENAME"
          final List<String> aParts = a.name.split(',');
          final List<String> bParts = b.name.split(',');

          // Get last name (before comma)
          final String aLastName =
              aParts.isNotEmpty ? aParts[0].trim() : a.name;
          final String bLastName =
              bParts.isNotEmpty ? bParts[0].trim() : b.name;

          // Compare last names first
          final int lastNameCompare =
              aLastName.toLowerCase().compareTo(bLastName.toLowerCase());
          if (lastNameCompare != 0) {
            return filters.sortDirection == SortDirection.ascending
                ? lastNameCompare
                : -lastNameCompare;
          }

          // If last names are equal, compare first names
          final String aFirstName =
              aParts.length > 1 ? aParts[1].trim().split(' ')[0] : '';
          final String bFirstName =
              bParts.length > 1 ? bParts[1].trim().split(' ')[0] : '';

          final int firstNameCompare =
              aFirstName.toLowerCase().compareTo(bFirstName.toLowerCase());
          if (firstNameCompare != 0) {
            return filters.sortDirection == SortDirection.ascending
                ? firstNameCompare
                : -firstNameCompare;
          }

          // If first names are equal, compare middle names
          final List<String> aNameParts =
              aParts.length > 1 ? aParts[1].trim().split(' ') : <String>[];
          final List<String> bNameParts =
              bParts.length > 1 ? bParts[1].trim().split(' ') : <String>[];

          final String aMiddleName =
              aNameParts.length > 1 ? aNameParts[1] : '';
          final String bMiddleName =
              bNameParts.length > 1 ? bNameParts[1] : '';

          final int middleNameCompare =
              aMiddleName.toLowerCase().compareTo(bMiddleName.toLowerCase());
          return filters.sortDirection == SortDirection.ascending
              ? middleNameCompare
              : -middleNameCompare;
        });
        break;

      case SortField.charges:
        sorted.sort((JailBooking a, JailBooking b) {
          final int aCharges = a.charges.length;
          final int bCharges = b.charges.length;
          final int compare = aCharges.compareTo(bCharges);
          // For charges, ascending means most charges first (highest to lowest)
          return filters.sortDirection == SortDirection.ascending
              ? -compare
              : compare;
        });
        break;

      case SortField.date:
      case SortField.none:
        // Date sorting is handled in SQL, none means no sorting
        break;
    }

    return sorted;
  }

  @override
  Future<List<PersonWithCharge>> getPeopleByCharge(
    String chargeName,
    String timeRange,
  ) async {
    try {
      final DateTime now = DateTime.now();
      dynamic query = _client.from(AppConfig.bookingsTable).select('*');

      // Convert time range format from UI (THISYEAR, 5YEARS, ALL) to repository format
      String repositoryTimeRange = timeRange;
      if (timeRange == 'THISYEAR') {
        repositoryTimeRange = AppConfig.timeRangeThisYear;
      } else if (timeRange == '5YEARS') {
        repositoryTimeRange = AppConfig.timeRange5Years;
      } else if (timeRange == 'ALL') {
        repositoryTimeRange = AppConfig.timeRangeAll;
      }

      // Apply time filter
      query = _applyTimeFilter(query, repositoryTimeRange, now);

      // For ALL time range, we need to fetch in batches due to Supabase's 1000 row limit
      List<dynamic> allRows = <dynamic>[];
      if (repositoryTimeRange == AppConfig.timeRangeAll) {
        // Fetch in batches
        int offset = 0;
        const int batchSize = 1000;
        bool hasMore = true;

        while (hasMore) {
          final batchQuery = query.order('booking_date', ascending: false)
              .range(offset, offset + batchSize - 1);
          
          final List<dynamic> batch = await batchQuery
              .timeout(AppConfig.longTimeout) as List<dynamic>;
          
          allRows.addAll(batch);
          
          if (batch.length < batchSize) {
            hasMore = false;
          } else {
            offset += batchSize;
          }
        }
      } else {
        // For filtered time ranges, fetch directly (should be under 1000 rows)
        allRows = await query
            .order('booking_date', ascending: false)
            .timeout(AppConfig.longTimeout) as List<dynamic>;
      }

      final List<JailBooking> bookings = BookingParser.parseBookingList(allRows);

      // Normalize charge name for comparison (remove extra whitespace, normalize case)
      final String normalizedChargeName = _normalizeChargeName(chargeName);

      // Debug: Collect sample charge names to help diagnose matching issues
      final Set<String> sampleCharges = <String>{};
      int totalChargesChecked = 0;

      // Group by person name and count charges matching the charge name
      final Map<String, PersonWithCharge> personMap = <String, PersonWithCharge>{};

      for (final booking in bookings) {
        int chargeCount = 0;
        DateTime? earliestDate;

        // Count how many times this person was charged with this specific charge
        for (final chargeDetail in booking.chargeDetails) {
          totalChargesChecked++;
          final String normalizedCharge = _normalizeChargeName(chargeDetail.charge);
          
          // Collect sample charges for debugging (first 10 unique)
          if (sampleCharges.length < 10 && normalizedCharge.isNotEmpty) {
            sampleCharges.add(normalizedCharge);
          }
          
          if (normalizedCharge == normalizedChargeName) {
            chargeCount++;
            if (earliestDate == null ||
                booking.bookingDate.isBefore(earliestDate)) {
              earliestDate = booking.bookingDate;
            }
          }
        }

        if (chargeCount > 0) {
          final String name = booking.name;
          if (personMap.containsKey(name)) {
            // Update count and earliest date
            final existing = personMap[name]!;
            personMap[name] = PersonWithCharge(
              name: name,
              bookingDate: existing.bookingDate.isBefore(earliestDate!)
                  ? existing.bookingDate
                  : earliestDate,
              count: existing.count + chargeCount,
            );
          } else {
            personMap[name] = PersonWithCharge(
              name: name,
              bookingDate: earliestDate!,
              count: chargeCount,
            );
          }
        }
      }

      // Debug output (only in debug mode)
      if (personMap.isEmpty && bookings.isNotEmpty) {
        debugPrint(
          '[getPeopleByCharge] No matches found. '
          'Searching for: "$normalizedChargeName" '
          '($chargeName). '
          'Checked $totalChargesChecked charges. '
          'Sample charges: ${sampleCharges.take(5).join(", ")}',
        );
      }

      // Convert to list and sort by count (descending), then by name
      final List<PersonWithCharge> result = personMap.values.toList()
        ..sort((a, b) {
          final countCompare = b.count.compareTo(a.count);
          if (countCompare != 0) return countCompare;
          return a.name.compareTo(b.name);
        });

      return result;
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException(
          'Failed to fetch people by charge: $chargeName',
          e,
        );
      }
      throw DatabaseException('Failed to load people by charge: $e');
    }
  }

  @override
  Future<List<JailBooking>> getBookingsByDate(DateTime date) async {
    try {
      // Get start and end of the day
      final DateTime startOfDay = DateTime(date.year, date.month, date.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      final List<dynamic> rows = await _client
          .from(AppConfig.bookingsTable)
          .select('*')
          .gte('booking_date', startOfDay.toIso8601String())
          .lt('booking_date', endOfDay.toIso8601String())
          .order('booking_date', ascending: false)
          .timeout(AppConfig.defaultTimeout) as List<dynamic>;

      return BookingParser.parseBookingList(rows);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException(
          'Failed to fetch bookings for date: $date',
          e,
        );
      }
      throw DatabaseException('Failed to load bookings for date: $e');
    }
  }

  /// Normalize charge name for comparison
  /// Removes extra whitespace, normalizes case, and handles common variations
  String _normalizeChargeName(String chargeName) {
    if (chargeName.isEmpty) return '';
    
    // Convert to uppercase and trim
    String normalized = chargeName.toUpperCase().trim();
    
    // Replace multiple spaces with single space
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove leading/trailing spaces again after replacement
    normalized = normalized.trim();
    
    return normalized;
  }
}

