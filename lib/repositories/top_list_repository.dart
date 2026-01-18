import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../exceptions/app_exceptions.dart';
import '../models/top_list_item.dart';
import '../services/supabase_service.dart';

/// Abstract repository for Top 100 list operations
abstract class TopListRepository {
  /// Get Top 100 arrested persons (by booking count)
  /// timeRange: 'THISYEAR', '5YEARS', or 'ALL'
  Future<List<TopListItem>> getTopArrestedPersons({String timeRange = 'ALL'});

  /// Get Top 100 felony charges (any degree)
  /// timeRange: 'THISYEAR', '5YEARS', or 'ALL'
  Future<List<TopListItem>> getTopFelonyCharges({String timeRange = 'ALL'});

  /// Get Top 100 misdemeanor charges
  /// timeRange: 'THISYEAR', '5YEARS', or 'ALL'
  Future<List<TopListItem>> getTopMisdemeanorCharges({
    String timeRange = 'ALL',
  });

  /// Get Top 100 all charges (felony and misdemeanor combined)
  /// timeRange: 'THISYEAR', '5YEARS', or 'ALL'
  Future<List<TopListItem>> getTopAllCharges({String timeRange = 'ALL'});

  /// Get Top 100 booking days (days with most bookings)
  /// timeRange: 'THISYEAR', '5YEARS', or 'ALL'
  Future<List<TopListItem>> getTopBookingDays({String timeRange = 'ALL'});
}

/// Supabase implementation of TopListRepository
class SupabaseTopListRepository implements TopListRepository {
  SupabaseTopListRepository() : _client = SupabaseService.client;

  final SupabaseClient _client;

  /// Helper method to get the latest calculation timestamp for a category and time_range
  Future<DateTime?> _getLatestCalculationTime(
    String category,
    String timeRange,
  ) async {
    try {
      final response = await _client
          .from('top_100_lists')
          .select('calculated_at')
          .eq('category', category)
          .eq('time_range', timeRange)
          .order('calculated_at', ascending: false)
          .limit(1)
          .single()
          .timeout(AppConfig.shortTimeout);

      if (response['calculated_at'] != null) {
        return DateTime.parse(response['calculated_at'] as String);
      }
      return null;
    } catch (e) {
      // If no data exists yet, return null
      return null;
    }
  }

  /// Helper method to fetch pre-calculated top 100 list from database
  Future<List<TopListItem>> _getPreCalculatedList(
    String category,
    String timeRange,
  ) async {
    try {
      // Get the most recent calculation for this category and time range
      final latestTime = await _getLatestCalculationTime(category, timeRange);

      if (latestTime == null) {
        debugPrint(
          '[TopList] No pre-calculated data found for $category (time_range: $timeRange)',
        );
        return [];
      }

      debugPrint(
        '[TopList] Fetching pre-calculated top 100 for $category, time_range: $timeRange (calculated at $latestTime)',
      );

      // Fetch the top 100 items for this category and time range from the latest calculation
      final response = await _client
          .from('top_100_lists')
          .select()
          .eq('category', category)
          .eq('time_range', timeRange)
          .eq('calculated_at', latestTime.toIso8601String())
          .order('rank', ascending: true)
          .limit(100)
          .timeout(AppConfig.defaultTimeout);

      final List<dynamic> rows = response as List<dynamic>;

      debugPrint(
        '[TopList] Retrieved ${rows.length} items for $category (time_range: $timeRange)',
      );

      return rows.map((row) {
        return TopListItem(
          rank: row['rank'] as int,
          label: row['label'] as String,
          count: row['count'] as int,
          subtitle: row['subtitle'] as String?,
          extraData: row['extra_data'] as Map<String, dynamic>?,
        );
      }).toList();
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException(
          'Failed to fetch pre-calculated top 100 for $category (time_range: $timeRange)',
          e,
        );
      }
      throw DatabaseException('Failed to load top list: $e');
    }
  }

  @override
  Future<List<TopListItem>> getTopArrestedPersons({
    String timeRange = 'ALL',
  }) async {
    return _getPreCalculatedList('arrested_persons', timeRange);
  }

  @override
  Future<List<TopListItem>> getTopFelonyCharges({
    String timeRange = 'ALL',
  }) async {
    return _getPreCalculatedList('felony_charges', timeRange);
  }

  @override
  Future<List<TopListItem>> getTopMisdemeanorCharges({
    String timeRange = 'ALL',
  }) async {
    return _getPreCalculatedList('misdemeanor_charges', timeRange);
  }

  @override
  Future<List<TopListItem>> getTopAllCharges({String timeRange = 'ALL'}) async {
    return _getPreCalculatedList('all_charges', timeRange);
  }

  @override
  Future<List<TopListItem>> getTopBookingDays({
    String timeRange = 'ALL',
  }) async {
    return _getPreCalculatedList('booking_days', timeRange);
  }
}
