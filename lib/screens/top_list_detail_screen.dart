import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/top_list_item.dart';
import '../providers/top_list_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

/// Time range presets for the Top 100 list filter. The first 4 are pre-
/// calculated nightly into `top_100_lists`. CUSTOM triggers a live SQL
/// query against `top_100_for_custom_range()`.
enum _TimeRange { ytd, m12, m24, m36, custom }

extension _TimeRangeX on _TimeRange {
  /// DB key for the pre-calculated rows. CUSTOM has no key (live).
  String? get dbKey {
    switch (this) {
      case _TimeRange.ytd: return 'YTD';
      case _TimeRange.m12: return '12MONTHS';
      case _TimeRange.m24: return '24MONTHS';
      case _TimeRange.m36: return '36MONTHS';
      case _TimeRange.custom: return null;
    }
  }

  String displayLabel({int? currentYear}) {
    switch (this) {
      case _TimeRange.ytd: return '${currentYear ?? DateTime.now().year} YTD';
      case _TimeRange.m12: return 'PAST 12 MONTHS';
      case _TimeRange.m24: return 'PAST 24 MONTHS';
      case _TimeRange.m36: return 'PAST 36 MONTHS';
      case _TimeRange.custom: return 'CUSTOM DATE RANGE';
    }
  }
}

/// For Arrested Persons only — client-side re-sort within the same top 100.
enum _ArrestedSort { bookings, charges }

/// Reusable screen for displaying Top 100 lists
class TopListDetailScreen extends ConsumerStatefulWidget {
  const TopListDetailScreen({
    required this.category,
    super.key,
  });

  final TopListCategory category;

  @override
  ConsumerState<TopListDetailScreen> createState() => _TopListDetailScreenState();
}

class _TopListDetailScreenState extends ConsumerState<TopListDetailScreen> {
  _TimeRange _selectedRange = _TimeRange.ytd;
  DateTimeRange? _customRange;
  _ArrestedSort _arrestedSort = _ArrestedSort.bookings;

  String _categoryDbKey() {
    switch (widget.category) {
      case TopListCategory.arrestedPersons:    return 'arrested_persons';
      case TopListCategory.felonyCharges:      return 'felony_charges';
      case TopListCategory.misdemeanorCharges: return 'misdemeanor_charges';
      case TopListCategory.allCharges:         return 'all_charges';
      case TopListCategory.bookingDays:        return 'booking_days';
    }
  }

  AsyncValue<List<TopListItem>> _watchData() {
    if (_selectedRange == _TimeRange.custom) {
      final DateTimeRange? r = _customRange;
      if (r == null) {
        return const AsyncValue<List<TopListItem>>.data(<TopListItem>[]);
      }
      return ref.watch(topListCustomRangeProvider((
        category: _categoryDbKey(),
        start: r.start,
        end: r.end,
      )));
    }
    final String tr = _selectedRange.dbKey!;
    switch (widget.category) {
      case TopListCategory.arrestedPersons:    return ref.watch(topArrestedPersonsProvider(tr));
      case TopListCategory.felonyCharges:      return ref.watch(topFelonyChargesProvider(tr));
      case TopListCategory.misdemeanorCharges: return ref.watch(topMisdemeanorChargesProvider(tr));
      case TopListCategory.allCharges:         return ref.watch(topAllChargesProvider(tr));
      case TopListCategory.bookingDays:        return ref.watch(topBookingDaysProvider(tr));
    }
  }

  Future<void> _pickCustomRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      saveText: 'APPLY',
    );
    if (picked != null && mounted) {
      setState(() {
        _customRange = picked;
        _selectedRange = _TimeRange.custom;
      });
    }
  }

  /// Apply Order By for arrested_persons and re-rank the result.
  List<TopListItem> _applyClientSort(List<TopListItem> items) {
    if (widget.category != TopListCategory.arrestedPersons) return items;
    if (_arrestedSort == _ArrestedSort.bookings) return items;
    final List<TopListItem> sorted = List<TopListItem>.from(items)
      ..sort((TopListItem a, TopListItem b) =>
          (b.chargesCount ?? 0).compareTo(a.chargesCount ?? 0));
    // Re-number rank to reflect the new sort order.
    return List<TopListItem>.generate(sorted.length, (int i) => TopListItem(
      rank: i + 1,
      label: sorted[i].label,
      count: sorted[i].count,
      subtitle: sorted[i].subtitle,
      extraData: sorted[i].extraData,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final AsyncValue<List<TopListItem>> dataAsync = _watchData();
    final bool isArrested = widget.category == TopListCategory.arrestedPersons;

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[appColors.accentPink, appColors.accentPinkDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.emoji_events, color: appColors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(widget.category.title,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: appColors.white)),
                      const SizedBox(height: 4),
                      Text(widget.category.subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: appColors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Time Range Filter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: appColors.lightPurple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.filter_list, size: 20, color: appColors.primaryPurple),
                    const SizedBox(width: 8),
                    Text('TIME RANGE:',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: appColors.primaryPurple)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<_TimeRange>(
                        value: _selectedRange,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        dropdownColor: appColors.cardBackground,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: appColors.textDark),
                        items: _TimeRange.values
                            .map((r) => DropdownMenuItem<_TimeRange>(
                                  value: r,
                                  child: Text(r.displayLabel()),
                                ))
                            .toList(),
                        onChanged: (_TimeRange? r) async {
                          if (r == null) return;
                          if (r == _TimeRange.custom) {
                            await _pickCustomRange();
                          } else {
                            setState(() => _selectedRange = r);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (_selectedRange == _TimeRange.custom && _customRange != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 28),
                    child: Row(
                      children: <Widget>[
                        Text('${_fmt(_customRange!.start)} – ${_fmt(_customRange!.end)}',
                            style: TextStyle(
                                fontSize: 12, color: appColors.textDark)),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _pickCustomRange,
                          icon: const Icon(Icons.edit_calendar, size: 16),
                          label: const Text('CHANGE'),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0)),
                        ),
                      ],
                    ),
                  ),
                if (isArrested) ...<Widget>[
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Icon(Icons.sort, size: 20, color: appColors.primaryPurple),
                      const SizedBox(width: 8),
                      Text('ORDER BY:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: appColors.primaryPurple)),
                      const SizedBox(width: 12),
                      _orderChip(_ArrestedSort.bookings, 'BOOKINGS'),
                      const SizedBox(width: 8),
                      _orderChip(_ArrestedSort.charges, 'CHARGES'),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // List
          Expanded(
            child: dataAsync.when(
              data: (items) {
                final List<TopListItem> sorted = _applyClientSort(items);
                if (sorted.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _selectedRange == _TimeRange.custom && _customRange == null
                            ? 'PICK A DATE RANGE TO SEE RESULTS'
                            : 'NO DATA AVAILABLE',
                        style: TextStyle(fontSize: 16, color: appColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  itemBuilder: (BuildContext ctx, int i) =>
                      _buildListItem(ctx, appColors, sorted[i], widget.category, isArrested),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.error_outline, size: 64, color: appColors.accentPink),
                      const SizedBox(height: 16),
                      Text('ERROR LOADING DATA',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: appColors.textDark)),
                      const SizedBox(height: 8),
                      Text(error.toString(),
                          style: TextStyle(fontSize: 12, color: appColors.textLight),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _orderChip(_ArrestedSort sort, String label) {
    final appColors = context.appColors;
    final bool selected = _arrestedSort == sort;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? appColors.white : appColors.textDark)),
      selected: selected,
      selectedColor: appColors.primaryPurple,
      backgroundColor: appColors.cardBackground,
      onSelected: (_) => setState(() => _arrestedSort = sort),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildListItem(
    BuildContext context,
    dynamic appColors,
    TopListItem item,
    TopListCategory category,
    bool isArrested,
  ) {
    final Widget cardContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getRankColor(item.rank, appColors),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('#${item.rank}',
                  style: TextStyle(
                      fontSize: _getRankFontSize(item.rank),
                      fontWeight: FontWeight.bold,
                      color: appColors.white)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: appColors.textDark)),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(item.subtitle!,
                      style: TextStyle(fontSize: 12, color: appColors.textLight)),
                ],
              ],
            ),
          ),
          // Counts column — for arrested_persons, two stacked metrics; else single.
          if (isArrested && item.chargesCount != null)
            _twoMetricColumn(appColors, item)
          else
            _singleMetricColumn(appColors, item, category),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: appColors.textLight, size: 20),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _handleCardTap(context, item, category),
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      ),
    );
  }

  Widget _singleMetricColumn(dynamic appColors, TopListItem item, TopListCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(item.formattedCount,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: appColors.primaryPurple)),
        Text(category.countLabel.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: appColors.textLight)),
      ],
    );
  }

  Widget _twoMetricColumn(dynamic appColors, TopListItem item) {
    final bool charges = _arrestedSort == _ArrestedSort.charges;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(item.formattedCount,
                style: TextStyle(
                    fontSize: charges ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    color: charges ? appColors.textLight : appColors.primaryPurple)),
            const SizedBox(width: 4),
            Text('B',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: charges ? appColors.textLight : appColors.primaryPurple)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(item.formattedChargesCount ?? '—',
                style: TextStyle(
                    fontSize: charges ? 18 : 14,
                    fontWeight: FontWeight.bold,
                    color: charges ? appColors.primaryPurple : appColors.textLight)),
            const SizedBox(width: 4),
            Text('C',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: charges ? appColors.primaryPurple : appColors.textLight)),
          ],
        ),
      ],
    );
  }

  void _handleCardTap(BuildContext context, TopListItem item, TopListCategory category) {
    switch (category) {
      case TopListCategory.arrestedPersons:
        context.push(RoutePaths.personChargeBreakdown, extra: item.label);
        break;
      case TopListCategory.felonyCharges:
      case TopListCategory.misdemeanorCharges:
      case TopListCategory.allCharges:
        context.push(
          RoutePaths.peopleByCharge,
          extra: <String, dynamic>{
            'chargeName': item.label,
            'timeRange': _selectedRange.dbKey ?? 'CUSTOM',
          },
        );
        break;
      case TopListCategory.bookingDays:
        DateTime? bookingDate;
        if (item.label.contains('-')) {
          bookingDate = DateTime.tryParse(item.label);
        } else if (item.label.contains('/')) {
          final parts = item.label.split('/');
          if (parts.length == 3) {
            final m = int.tryParse(parts[0]);
            final d = int.tryParse(parts[1]);
            final y = int.tryParse(parts[2]);
            if (m != null && d != null && y != null) {
              bookingDate = DateTime(y, m, d);
            }
          }
        }
        if (bookingDate != null) {
          context.push(RoutePaths.bookingsByDate, extra: bookingDate);
        }
        break;
    }
  }

  Color _getRankColor(int rank, dynamic appColors) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return appColors.primaryPurple as Color;
  }

  double _getRankFontSize(int rank) {
    if (rank >= 100) return 11.0;
    if (rank >= 10) return 14.0;
    return 16.0;
  }

  String _fmt(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
}
