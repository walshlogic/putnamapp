import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../exceptions/app_exceptions.dart';
import '../models/traffic_citation.dart';
import '../models/traffic_citation_filters.dart';

/// Abstract repository for traffic citation operations
abstract class TrafficCitationRepository {
  /// Get traffic citations with filters and pagination
  Future<TrafficCitationResults> getCitations(TrafficCitationFilters filters);

  /// Get a single citation by case number
  Future<TrafficCitation?> getCitationByCaseNumber(String caseNumber);

  /// Get citations by name
  Future<List<TrafficCitation>> getCitationsByName(String name);

  /// Get citations by person (name + date of birth)
  Future<List<TrafficCitation>> getCitationsByPerson(
    String lastName,
    String firstName,
    DateTime dateOfBirth,
  );
}

/// Supabase implementation of TrafficCitationRepository
class SupabaseTrafficCitationRepository implements TrafficCitationRepository {
  SupabaseTrafficCitationRepository(this._client);

  final SupabaseClient _client;

  /// Apply time filter to query
  dynamic _applyTimeFilter(dynamic query, String timeRange) {
    final DateTime now = DateTime.now();
    
    if (timeRange == AppConfig.timeRangeThisYear) {
      // Calculate 12 months ago from today (past 12 months)
      // Subtract 12 months, handling year boundaries correctly
      final DateTime cutoff = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 365));
      return query.gte('citation_date', cutoff.toIso8601String().split('T')[0]);
    } else if (timeRange == AppConfig.timeRange5Years) {
      final DateTime cutoff = DateTime(now.year - 5, now.month, now.day);
      return query.gte('citation_date', cutoff.toIso8601String().split('T')[0]);
    }
    // If 'ALL', no time filter
    return query;
  }

  @override
  Future<TrafficCitationResults> getCitations(
    TrafficCitationFilters filters,
  ) async {
    try {
      // Build query matching bookings pattern exactly
      dynamic query = _client.from(AppConfig.trafficCitationsTable).select('*');

      // Apply time range filter
      query = _applyTimeFilter(query, filters.timeRange);

      // Apply other filters
      if (filters.city != null && filters.city!.isNotEmpty) {
        query = query.ilike('city', '%${filters.city}%');
      }

      if (filters.violationType != null && filters.violationType!.isNotEmpty) {
        query = query.ilike('violation_description', '%${filters.violationType}%');
      }

      if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
        final String search = filters.searchQuery!.trim();
        
        // Check if search contains comma (lastname, firstname format)
        if (search.contains(',')) {
          final List<String> nameParts = search.split(',').map((s) => s.trim()).toList();
          final String lastName = nameParts.isNotEmpty ? nameParts[0] : '';
          final String firstName = nameParts.length > 1 ? nameParts[1] : '';
          
          if (lastName.isNotEmpty && firstName.isNotEmpty) {
            // Search both last and first name
            query = query
                .ilike('last_name', '%$lastName%')
                .ilike('first_name', '%$firstName%');
          } else if (lastName.isNotEmpty) {
            query = query.ilike('last_name', '%$lastName%');
          }
        } else {
          // Standard search across all fields
          query = query.or(
            'last_name.ilike.%$search%,first_name.ilike.%$search%,license_plate.ilike.%$search%,case_number.ilike.%$search%,full_case_number.ilike.%$search%',
          );
        }
      }

      // Apply sorting
      if (filters.sortBy == AppConfig.sortByDate) {
        query = query.order('citation_date', ascending: filters.sortOrder == AppConfig.sortOrderAsc);
      } else if (filters.sortBy == AppConfig.sortByName) {
        final String nameColumn = filters.nameSortBy == AppConfig.nameSortByFirstName 
            ? 'first_name' 
            : 'last_name';
        query = query.order(nameColumn, ascending: filters.sortOrder == AppConfig.sortOrderAsc);
      }

      // Pagination
      final int from = (filters.page - 1) * filters.pageSize;
      final int to = from + filters.pageSize - 1;
      query = query.range(from, to);

      // Execute query with timeout
      final List<dynamic> data = await query
          .timeout(AppConfig.longTimeout) as List<dynamic>;

      final List<TrafficCitation> citations = data
          .map((json) => TrafficCitation.fromJson(json as Map<String, dynamic>))
          .toList();

      // Simple count estimate for now (can optimize later)
      final int totalCount = citations.length == filters.pageSize
          ? citations.length * 100 // Estimate
          : citations.length;

      return TrafficCitationResults(
        citations: citations,
        totalCount: totalCount,
        page: filters.page,
        pageSize: filters.pageSize,
      );
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch traffic citations', e);
      }
      throw DatabaseException('Failed to load traffic citations: $e');
    }
  }

  @override
  Future<TrafficCitation?> getCitationByCaseNumber(String caseNumber) async {
    try {
      final response = await _client
          .from(AppConfig.trafficCitationsTable)
          .select()
          .eq('case_number', caseNumber)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return TrafficCitation.fromJson(response);
    } catch (e) {
      throw DatabaseException('Failed to fetch traffic citation', e);
    }
  }

  @override
  Future<List<TrafficCitation>> getCitationsByName(String name) async {
    try {
      final String searchName = name.trim().toUpperCase();

      // Split name into parts (assuming "Last, First" or "Last First" format)
      final List<String> nameParts = searchName
          .split(',')
          .map((s) => s.trim())
          .toList();
      final String lastName = nameParts.isNotEmpty ? nameParts[0] : searchName;
      final String firstName = nameParts.length > 1 ? nameParts[1] : '';

      dynamic query = _client
          .from(AppConfig.trafficCitationsTable)
          .select()
          .ilike('last_name', '%$lastName%');

      if (firstName.isNotEmpty) {
        query = query.ilike('first_name', '%$firstName%');
      }

      query = query.order('citation_date', ascending: false).limit(100);

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;

      return data
          .map((json) => TrafficCitation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch citations by name', e);
    }
  }

  /// Get citations by name and date of birth (for person detail screen)
  @override
  Future<List<TrafficCitation>> getCitationsByPerson(
    String lastName,
    String firstName,
    DateTime dateOfBirth,
  ) async {
    try {
      // Format date of birth as YYYY-MM-DD for comparison
      final String dobString = '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';

      dynamic query = _client
          .from(AppConfig.trafficCitationsTable)
          .select()
          .ilike('last_name', lastName.toUpperCase())
          .ilike('first_name', firstName.toUpperCase())
          .eq('date_of_birth', dobString)
          .order('citation_date', ascending: false);

      final List<dynamic> data = await query as List<dynamic>;

      return data
          .map((json) => TrafficCitation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch citations by person', e);
    }
  }
}
