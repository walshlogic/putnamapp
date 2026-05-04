import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../exceptions/app_exceptions.dart';
import '../models/top_list_item.dart';
import '../services/supabase_service.dart';

/// Abstract repository for Top 100 list operations.
///
/// Pre-calculated ranges: 'YTD', '12MONTHS', '24MONTHS', '36MONTHS' — all
/// refreshed nightly at 4 AM by `public.calculate_top_100_lists()`. For an
/// arbitrary user-picked date range, use [getTopForCustomRange] which
/// invokes the live `public.top_100_for_custom_range()` Postgres function.
abstract class TopListRepository {
  Future<List<TopListItem>> getTopArrestedPersons({String timeRange = 'YTD'});
  Future<List<TopListItem>> getTopFelonyCharges({String timeRange = 'YTD'});
  Future<List<TopListItem>> getTopMisdemeanorCharges({String timeRange = 'YTD'});
  Future<List<TopListItem>> getTopAllCharges({String timeRange = 'YTD'});
  Future<List<TopListItem>> getTopBookingDays({String timeRange = 'YTD'});

  /// Live custom date range query. `category` matches the same set used by
  /// the pre-calculated lists (arrested_persons, felony_charges, etc.).
  /// Both dates are inclusive.
  Future<List<TopListItem>> getTopForCustomRange({
    required String category,
    required DateTime start,
    required DateTime end,
  });
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
    String timeRange = 'YTD',
  }) async {
    return _getPreCalculatedList('arrested_persons', timeRange);
  }

  @override
  Future<List<TopListItem>> getTopFelonyCharges({
    String timeRange = 'YTD',
  }) async {
    return _getPreCalculatedList('felony_charges', timeRange);
  }

  @override
  Future<List<TopListItem>> getTopMisdemeanorCharges({
    String timeRange = 'YTD',
  }) async {
    return _getPreCalculatedList('misdemeanor_charges', timeRange);
  }

  @override
  Future<List<TopListItem>> getTopAllCharges({String timeRange = 'YTD'}) async {
    return _getPreCalculatedList('all_charges', timeRange);
  }

  @override
  Future<List<TopListItem>> getTopBookingDays({
    String timeRange = 'YTD',
  }) async {
    return _getPreCalculatedList('booking_days', timeRange);
  }

  @override
  Future<List<TopListItem>> getTopForCustomRange({
    required String category,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final String startIso = _yyyymmdd(start);
      final String endIso = _yyyymmdd(end);
      debugPrint(
        '[TopList] Custom range: $category from $startIso to $endIso',
      );
      final dynamic response = await _client
          .rpc(
            'top_100_for_custom_range',
            params: <String, dynamic>{
              'p_category': category,
              'p_start': startIso,
              'p_end': endIso,
            },
          )
          .timeout(AppConfig.defaultTimeout);
      final List<dynamic> rows = response as List<dynamic>;
      debugPrint('[TopList] Custom range returned ${rows.length} rows');
      return rows.map((row) {
        final Map<String, dynamic> r = row as Map<String, dynamic>;
        return TopListItem(
          rank: r['rank'] as int,
          label: r['label'] as String,
          count: r['count'] as int,
          subtitle: r['subtitle'] as String?,
          extraData: r['extra_data'] as Map<String, dynamic>?,
        );
      }).toList();
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException(
          'Failed to fetch custom-range top 100 for $category',
          e,
        );
      }
      throw DatabaseException('Failed to load custom-range top list: $e');
    }
  }

  static String _yyyymmdd(DateTime d) {
    final String y = d.year.toString().padLeft(4, '0');
    final String m = d.month.toString().padLeft(2, '0');
    final String day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
