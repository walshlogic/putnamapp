import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import 'supabase_service.dart';

/// Service for reading Putnam County Property Appraiser (PPA) TRIM data from
/// the `ppa` schema. Read-only from the client; writes happen via the ingest
/// pipeline under `ingest/ppa_trim/` using the service_role connection.
class PpaService {
  PpaService._();

  static final PpaService instance = PpaService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Fuzzy search parcels by physical address. Returns rows from
  /// `ppa.v_parcel_summary`. Backed by a pg_trgm GIN index on
  /// `parcels.physical_address`, so `%q%` stays cheap.
  Future<List<Map<String, dynamic>>> searchByAddress(
    String q, {
    int limit = 25,
  }) async {
    final query = q.trim();
    if (query.isEmpty) return const <Map<String, dynamic>>[];
    try {
      final List<Map<String, dynamic>> rows = await _client
          .schema('ppa')
          .from('v_parcel_summary')
          .select()
          .ilike('physical_address', '%$query%')
          .order('physical_address')
          .limit(limit);
      return rows;
    } catch (e) {
      debugPrint('❌ PpaService.searchByAddress: $e');
      throw DatabaseException('Failed to search parcels by address', e);
    }
  }

  /// Fuzzy search parcels by owner name. Returns rows from
  /// `ppa.v_parcel_summary`. Backed by a pg_trgm GIN index on
  /// `parcels.owner_name`.
  Future<List<Map<String, dynamic>>> searchByOwner(
    String q, {
    int limit = 25,
  }) async {
    final query = q.trim();
    if (query.isEmpty) return const <Map<String, dynamic>>[];
    try {
      final List<Map<String, dynamic>> rows = await _client
          .schema('ppa')
          .from('v_parcel_summary')
          .select()
          .ilike('owner_name', '%$query%')
          .order('owner_name')
          .limit(limit);
      return rows;
    } catch (e) {
      debugPrint('❌ PpaService.searchByOwner: $e');
      throw DatabaseException('Failed to search parcels by owner', e);
    }
  }

  /// Full parcel record with joined exemptions, taxing_authorities, and
  /// non_ad_valorem rows for the detail screen. If [rollYear] is omitted, the
  /// most recent roll year for that parcel is returned.
  Future<Map<String, dynamic>> getParcelDetail(
    String parcelNumber, {
    int? rollYear,
  }) async {
    final parcel = parcelNumber.trim().replaceAll(RegExp(r'\*$'), '');
    if (parcel.isEmpty) {
      throw const ValidationException('Parcel number is required', 'parcelNumber');
    }
    try {
      final query = _client
          .schema('ppa')
          .from('parcels')
          .select(
            '*, '
            'exemptions(seq, description, tax_district, amount), '
            'taxing_authorities('
            'authority_type, authority_label, '
            'taxable_ly, millage_ly, taxes_ly, '
            'taxable_cy, millage_proposed, taxes_proposed, '
            'millage_rollback, taxes_rollback), '
            'non_ad_valorem(seq, description, rate, units, amount)',
          )
          .eq('parcel_number', parcel);

      final Map<String, dynamic>? row = rollYear != null
          ? await query.eq('roll_year', rollYear).maybeSingle()
          : await query
                .order('roll_year', ascending: false)
                .limit(1)
                .maybeSingle();

      if (row == null) {
        throw NotFoundException.resource('Parcel $parcel');
      }
      return row;
    } catch (e) {
      if (e is NotFoundException || e is ValidationException) rethrow;
      debugPrint('❌ PpaService.getParcelDetail: $e');
      throw DatabaseException('Failed to load parcel detail', e);
    }
  }

  /// Rough ad-valorem tax estimate for a what-if calculator. Samples one
  /// representative `millage_proposed` per `authority_type` for [rollYear]
  /// (millages are set at the authority level, so any parcel in a given
  /// authority sees the same rate), sums them, and applies to [taxableValue]:
  /// `tax = sum(millage) * taxableValue / 1000`.
  ///
  /// This is an approximation — a specific parcel's actual bill depends on
  /// which districts apply (e.g. municipality only for in-city parcels, fire
  /// MSTU only in the fire district). For a precise figure use
  /// [getParcelDetail] and sum its `taxing_authorities.taxes_proposed`.
  Future<double> estimateTax({
    required num taxableValue,
    required int rollYear,
  }) async {
    if (taxableValue < 0) {
      throw const ValidationException('taxableValue must be non-negative', 'taxableValue');
    }
    try {
      final List<Map<String, dynamic>> rows = await _client
          .schema('ppa')
          .from('taxing_authorities')
          .select('authority_type, millage_proposed, parcels!inner(roll_year)')
          .eq('parcels.roll_year', rollYear)
          .not('millage_proposed', 'is', null)
          .limit(500);

      final Map<String, double> millageByType = <String, double>{};
      for (final row in rows) {
        final String type = row['authority_type'] as String;
        if (millageByType.containsKey(type)) continue;
        final num? mill = row['millage_proposed'] as num?;
        if (mill == null) continue;
        millageByType[type] = mill.toDouble();
      }

      final double totalMillage = millageByType.values.fold<double>(
        0.0,
        (sum, m) => sum + m,
      );
      return (totalMillage * taxableValue.toDouble()) / 1000.0;
    } catch (e) {
      if (e is ValidationException) rethrow;
      debugPrint('❌ PpaService.estimateTax: $e');
      throw DatabaseException('Failed to estimate tax', e);
    }
  }
}
