import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../exceptions/app_exceptions.dart';
import '../models/agency_stats.dart';

/// Abstract repository for agency statistics operations
abstract class AgencyStatsRepository {
  /// Get comprehensive statistics for a specific agency
  Future<AgencyStats> getAgencyStats(String agencyId, String agencyName);
}

/// Supabase implementation of AgencyStatsRepository
/// Now reads from pre-calculated agency_stats table instead of calculating on-the-fly
class SupabaseAgencyStatsRepository implements AgencyStatsRepository {
  SupabaseAgencyStatsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AgencyStats> getAgencyStats(
    String agencyId,
    String agencyName,
  ) async {
    try {
      debugPrint('[AgencyStats] Fetching pre-calculated stats for $agencyId from ${AppConfig.agencyStatsTable}');

      // Get the latest calculated stats for this agency
      try {
        final response = await _client
            .from(AppConfig.agencyStatsTable)
            .select()
            .eq('agency_id', agencyId)
            .order('calculated_at', ascending: false)
            .limit(1)
            .single()
            .timeout(AppConfig.defaultTimeout);

        // Parse JSONB fields (Supabase returns them as dynamic, not strings)
        final bookingsByYear = _parseJsonMap<int, int>(response['bookings_by_year']);
        final bookingsByGender = _parseJsonMap<String, int>(response['bookings_by_gender']);
        final bookingsByRace = _parseJsonMap<String, int>(response['bookings_by_race']);
        final chargesByLevelAndDegree = _parseChargesByLevelAndDegree(response['charges_by_level_and_degree']);

        debugPrint('[AgencyStats] ✅ Loaded cached stats for $agencyId');
        debugPrint('[AgencyStats]   - Total bookings: ${response['total_bookings']}');
        debugPrint('[AgencyStats]   - Total charges: ${response['total_charges']}');
        debugPrint('[AgencyStats]   - Calculated at: ${response['calculated_at']}');

        return AgencyStats(
          agencyId: agencyId,
          agencyName: response['agency_name'] as String? ?? agencyName,
          totalBookings: (response['total_bookings'] as num?)?.toInt() ?? 0,
          totalCharges: (response['total_charges'] as num?)?.toInt() ?? 0,
          bookingsByYear: bookingsByYear,
          bookingsByGender: bookingsByGender,
          bookingsByRace: bookingsByRace,
          chargesByLevelAndDegree: chargesByLevelAndDegree,
          uniquePersons: (response['unique_persons'] as num?)?.toInt() ?? 0,
          averageChargesPerBooking: (response['average_charges_per_booking'] as num?)?.toDouble() ?? 0.0,
        );
      } on PostgrestException catch (e) {
        // If no record found, return empty stats
        if (e.code == 'PGRST116') {
          debugPrint('[AgencyStats] No cached stats found for $agencyId, returning empty stats');
          return AgencyStats(
            agencyId: agencyId,
            agencyName: agencyName,
            totalBookings: 0,
            totalCharges: 0,
            bookingsByYear: {},
            bookingsByGender: {},
            bookingsByRace: {},
            chargesByLevelAndDegree: [],
            uniquePersons: 0,
            averageChargesPerBooking: 0.0,
          );
        }
        rethrow;
      }

    } catch (e) {
      if (e is PostgrestException) {
        debugPrint('[AgencyStats] ❌ Database error: ${e.message}');
        throw DatabaseException('Failed to fetch agency stats', e);
      }
      debugPrint('[AgencyStats] ❌ Error: $e');
      throw DatabaseException('Failed to load agency stats: $e');
    }
  }

  /// Parse JSONB field to Map
  /// Supabase returns JSONB as dynamic (Map or String), handle both cases
  Map<K, V> _parseJsonMap<K, V>(dynamic jsonData) {
    if (jsonData == null) {
      return <K, V>{};
    }
    
    // If already a Map, use it directly
    if (jsonData is Map) {
      if (K == int && V == int) {
        return jsonData.map((key, value) => MapEntry(int.parse(key.toString()) as K, value as V));
      }
      return jsonData.map((key, value) => MapEntry(key as K, value as V));
    }
    
    // If string, parse it
    if (jsonData is String) {
      if (jsonData.isEmpty) {
        return <K, V>{};
      }
      try {
        final decoded = jsonDecode(jsonData) as Map<String, dynamic>;
        if (K == int && V == int) {
          return decoded.map((key, value) => MapEntry(int.parse(key) as K, value as V));
        }
        return decoded.map((key, value) => MapEntry(key as K, value as V));
      } catch (e) {
        debugPrint('[AgencyStats] Error parsing JSON map string: $e');
        return <K, V>{};
      }
    }
    
    return <K, V>{};
  }

  /// Parse charges_by_level_and_degree JSONB array
  /// Supabase returns JSONB as dynamic (List or String), handle both cases
  List<ChargesByLevelAndDegree> _parseChargesByLevelAndDegree(dynamic jsonData) {
    if (jsonData == null) {
      return [];
    }
    
    // If already a List, use it directly
    if (jsonData is List) {
      return jsonData.map((item) {
        final map = item as Map<String, dynamic>;
        final byDegreeMap = (map['byDegree'] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(key, value as int)) ?? <String, int>{};
        
        return ChargesByLevelAndDegree(
          level: map['level'] as String? ?? 'UNKNOWN',
          totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
          byDegree: byDegreeMap,
        );
      }).toList();
    }
    
    // If string, parse it
    if (jsonData is String) {
      if (jsonData.isEmpty) {
        return [];
      }
      try {
        final decoded = jsonDecode(jsonData) as List<dynamic>;
        return decoded.map((item) {
          final map = item as Map<String, dynamic>;
          final byDegreeMap = (map['byDegree'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as int)) ?? <String, int>{};
          
          return ChargesByLevelAndDegree(
            level: map['level'] as String? ?? 'UNKNOWN',
            totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
            byDegree: byDegreeMap,
          );
        }).toList();
      } catch (e) {
        debugPrint('[AgencyStats] Error parsing charges_by_level_and_degree string: $e');
        return [];
      }
    }
    
    return [];
  }

}

