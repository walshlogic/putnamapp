import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/ori_record.dart';

class OriRecordResults {
  OriRecordResults({required this.records, required this.hasMore});
  final List<OriRecord> records;
  final bool hasMore;
}

class OriRecordFilters {
  const OriRecordFilters({
    this.searchQuery = '',
    this.timeRange = AppConfig.timeRangeThisYear,
    this.category = OriQuickCategory.all,
    this.additionalCodes = const <String>[],
    this.startDate,
    this.endDate,
    this.pageSize = 50,
    this.offset = 0,
  });

  final String searchQuery;
  final String timeRange;
  final OriQuickCategory category;
  final List<String> additionalCodes;
  final DateTime? startDate;
  final DateTime? endDate;
  final int pageSize;
  final int offset;

  OriRecordFilters copyWith({
    String? searchQuery,
    String? timeRange,
    OriQuickCategory? category,
    List<String>? additionalCodes,
    DateTime? startDate,
    DateTime? endDate,
    int? pageSize,
    int? offset,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return OriRecordFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      timeRange: timeRange ?? this.timeRange,
      category: category ?? this.category,
      additionalCodes: additionalCodes ?? this.additionalCodes,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      pageSize: pageSize ?? this.pageSize,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OriRecordFilters &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          timeRange == other.timeRange &&
          category == other.category &&
          _listEq(additionalCodes, other.additionalCodes) &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          pageSize == other.pageSize &&
          offset == other.offset;

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      timeRange.hashCode ^
      category.hashCode ^
      Object.hashAll(additionalCodes) ^
      (startDate?.hashCode ?? 0) ^
      (endDate?.hashCode ?? 0) ^
      pageSize.hashCode ^
      offset.hashCode;

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

abstract class OriRecordRepository {
  Future<OriRecordResults> search(OriRecordFilters filters);
  Future<OriRecord?> getById(int id);
}

class SupabaseOriRecordRepository implements OriRecordRepository {
  SupabaseOriRecordRepository(this._client);

  final SupabaseClient _client;
  static const String _table = 'ori_records';

  DateTime? _cutoffForTimeRange(String timeRange) {
    final DateTime now = DateTime.now();
    if (timeRange == AppConfig.timeRangeThisYear) {
      return DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 365));
    }
    if (timeRange == AppConfig.timeRange5Years) {
      return DateTime(now.year - 5, now.month, now.day);
    }
    return null;
  }

  @override
  Future<OriRecordResults> search(OriRecordFilters filters) async {
    dynamic query = _client.from(_table).select();

    final String q = filters.searchQuery.trim();
    if (q.isNotEmpty) {
      final String pattern = '%${q.toUpperCase()}%';
      query = query.or(
        'from_party.ilike.$pattern,to_party.ilike.$pattern,instrument_number.ilike.$pattern',
      );
    }

    final List<String> codes = <String>[
      ...oriQuickCategoryCodes[filters.category] ?? const <String>[],
      ...filters.additionalCodes,
    ];
    if (codes.isNotEmpty) {
      query = query.inFilter('transaction_code', codes);
    }

    final DateTime? effectiveStart = filters.startDate ??
        _cutoffForTimeRange(filters.timeRange);
    if (effectiveStart != null) {
      query = query.gte(
        'file_date',
        effectiveStart.toIso8601String().split('T')[0],
      );
    }
    if (filters.endDate != null) {
      query = query.lte(
        'file_date',
        filters.endDate!.toIso8601String().split('T')[0],
      );
    }

    final int limit = filters.pageSize + 1;
    final List<dynamic> rows = await query
        .order('file_date', ascending: false)
        .order('id', ascending: false)
        .range(filters.offset, filters.offset + limit - 1);

    final List<OriRecord> records = rows
        .take(filters.pageSize)
        .map((dynamic r) => OriRecord.fromJson(r as Map<String, dynamic>))
        .toList();

    return OriRecordResults(
      records: records,
      hasMore: rows.length > filters.pageSize,
    );
  }

  @override
  Future<OriRecord?> getById(int id) async {
    final List<dynamic> rows = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .limit(1);
    if (rows.isEmpty) return null;
    return OriRecord.fromJson(rows.first as Map<String, dynamic>);
  }
}
