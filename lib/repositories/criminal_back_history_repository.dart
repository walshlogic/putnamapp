import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../exceptions/app_exceptions.dart';
import '../models/criminal_back_history.dart';
import '../models/criminal_back_history_filters.dart';

/// Abstract repository for criminal back history operations
abstract class CriminalBackHistoryRepository {
  /// Get criminal back history cases with filters and pagination
  Future<CriminalBackHistoryResults> getCases(CriminalBackHistoryFilters filters);

  /// Get a single case by case number
  Future<CriminalBackHistory?> getCaseByCaseNumber(String caseNumber);

  /// Get cases by name
  Future<List<CriminalBackHistory>> getCasesByName(String name);

  /// Get cases by person (name + date of birth)
  Future<List<CriminalBackHistory>> getCasesByPerson(
    String lastName,
    String firstName,
    DateTime dateOfBirth,
  );
}

/// Supabase implementation of CriminalBackHistoryRepository
class SupabaseCriminalBackHistoryRepository implements CriminalBackHistoryRepository {
  SupabaseCriminalBackHistoryRepository(this._client);

  final SupabaseClient _client;

  /// Apply time filter to query
  dynamic _applyTimeFilter(dynamic query, String timeRange) {
    final DateTime now = DateTime.now();
    
    if (timeRange == AppConfig.timeRangeThisYear) {
      // Calculate 12 months ago from today (past 12 months)
      // Subtract 12 months, handling year boundaries correctly
      final DateTime cutoff = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 365));
      return query.gte('clerk_file_date', cutoff.toIso8601String().split('T')[0]);
    } else if (timeRange == AppConfig.timeRange5Years) {
      final DateTime cutoff = DateTime(now.year - 5, now.month, now.day);
      return query.gte('clerk_file_date', cutoff.toIso8601String().split('T')[0]);
    }
    // If 'ALL', no time filter
    return query;
  }

  @override
  Future<CriminalBackHistoryResults> getCases(
    CriminalBackHistoryFilters filters,
  ) async {
    try {
      // Build query
      dynamic query = _client.from(AppConfig.criminalBackHistoryTable).select('*');

      // Apply time range filter
      query = _applyTimeFilter(query, filters.timeRange);

      // Apply other filters
      if (filters.city != null && filters.city!.isNotEmpty) {
        query = query.ilike('city', '%${filters.city}%');
      }

      if (filters.statuteDescription != null && filters.statuteDescription!.isNotEmpty) {
        query = query.ilike('statute_description', '%${filters.statuteDescription}%');
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
                .ilike('defendant_last_name', '%$lastName%')
                .ilike('defendant_first_name', '%$firstName%');
          } else if (lastName.isNotEmpty) {
            query = query.ilike('defendant_last_name', '%$lastName%');
          }
        } else {
          // Standard search across all fields
          query = query.or(
            'defendant_last_name.ilike.%$search%,defendant_first_name.ilike.%$search%,case_number.ilike.%$search%,uniform_case_number.ilike.%$search%',
          );
        }
      }

      // Apply sorting
      if (filters.sortBy == AppConfig.sortByDate) {
        query = query.order('clerk_file_date', ascending: filters.sortOrder == AppConfig.sortOrderAsc);
      } else if (filters.sortBy == AppConfig.sortByName) {
        final String nameColumn = filters.nameSortBy == AppConfig.nameSortByFirstName 
            ? 'defendant_first_name' 
            : 'defendant_last_name';
        query = query.order(nameColumn, ascending: filters.sortOrder == AppConfig.sortOrderAsc);
      }

      // Pagination
      final int from = (filters.page - 1) * filters.pageSize;
      final int to = from + filters.pageSize - 1;
      query = query.range(from, to);

      // Execute query with timeout
      final List<dynamic> data = await query
          .timeout(AppConfig.longTimeout) as List<dynamic>;

      final List<CriminalBackHistory> cases = data
          .map((json) => CriminalBackHistory.fromJson(json as Map<String, dynamic>))
          .toList();

      // Simple count estimate for now (can optimize later)
      final int totalCount = cases.length == filters.pageSize
          ? cases.length * 100 // Estimate
          : cases.length;

      return CriminalBackHistoryResults(
        cases: cases,
        totalCount: totalCount,
        page: filters.page,
        pageSize: filters.pageSize,
      );
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch criminal back history', e);
      }
      throw DatabaseException('Failed to load criminal back history: $e');
    }
  }

  @override
  Future<CriminalBackHistory?> getCaseByCaseNumber(String caseNumber) async {
    try {
      final response = await _client
          .from(AppConfig.criminalBackHistoryTable)
          .select()
          .eq('case_number', caseNumber)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return CriminalBackHistory.fromJson(response);
    } catch (e) {
      throw DatabaseException('Failed to fetch criminal back history case', e);
    }
  }

  @override
  Future<List<CriminalBackHistory>> getCasesByName(String name) async {
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
          .from(AppConfig.criminalBackHistoryTable)
          .select()
          .ilike('defendant_last_name', '%$lastName%');

      if (firstName.isNotEmpty) {
        query = query.ilike('defendant_first_name', '%$firstName%');
      }

      query = query.order('clerk_file_date', ascending: false).limit(100);

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;

      return data
          .map((json) => CriminalBackHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch cases by name', e);
    }
  }

  /// Get cases by name and date of birth (for person detail screen)
  @override
  Future<List<CriminalBackHistory>> getCasesByPerson(
    String lastName,
    String firstName,
    DateTime dateOfBirth,
  ) async {
    try {
      // Format date of birth as YYYY-MM-DD for comparison
      final String dobString = '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';

      dynamic query = _client
          .from(AppConfig.criminalBackHistoryTable)
          .select()
          .ilike('defendant_last_name', lastName.toUpperCase())
          .ilike('defendant_first_name', firstName.toUpperCase())
          .eq('date_of_birth', dobString)
          .order('clerk_file_date', ascending: false);

      final List<dynamic> data = await query as List<dynamic>;

      return data
          .map((json) => CriminalBackHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch cases by person', e);
    }
  }
}

