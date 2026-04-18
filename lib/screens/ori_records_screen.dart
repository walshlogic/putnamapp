import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../config/route_names.dart';
import '../extensions/build_context_extensions.dart';
import '../models/ori_record.dart';
import '../providers/ori_record_providers.dart';
import '../repositories/ori_record_repository.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class OriRecordsScreen extends ConsumerStatefulWidget {
  const OriRecordsScreen({super.key});

  @override
  ConsumerState<OriRecordsScreen> createState() => _OriRecordsScreenState();
}

class _OriRecordsScreenState extends ConsumerState<OriRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  String _timeRange = AppConfig.timeRangeThisYear;
  OriQuickCategory _category = OriQuickCategory.all;
  List<String> _advancedCodes = const <String>[];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
    });
  }

  Future<void> _openFiltersSheet() async {
    final result = await showModalBottomSheet<_FilterSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _FilterSheet(
        initialCodes: _advancedCodes,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
    if (result == null) return;
    setState(() {
      _advancedCodes = result.codes;
      _startDate = result.startDate;
      _endDate = result.endDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final filters = OriRecordFilters(
      searchQuery: _searchQuery,
      timeRange: _timeRange,
      category: _category,
      additionalCodes: _advancedCodes,
      startDate: _startDate,
      endDate: _endDate,
    );
    final async = ref.watch(oriRecordSearchProvider(filters));

    final bool hasAdvanced = _advancedCodes.isNotEmpty ||
        _startDate != null ||
        _endDate != null;

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    hintText: 'Search party name or instrument #',
                    filled: true,
                    fillColor: appColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (final String tr in const <String>[
                        AppConfig.timeRangeThisYear,
                        AppConfig.timeRange5Years,
                        AppConfig.timeRangeAll,
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(tr),
                            selected: _timeRange == tr,
                            onSelected: (_) => setState(() {
                              _timeRange = tr;
                              _startDate = null;
                              _endDate = null;
                            }),
                            selectedColor: appColors.primaryPurple,
                            labelStyle: TextStyle(
                              color: _timeRange == tr
                                  ? appColors.white
                                  : appColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (final OriQuickCategory c in OriQuickCategory.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(oriQuickCategoryLabels[c] ?? c.name),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                            selectedColor: appColors.primaryPurple,
                            labelStyle: TextStyle(
                              color: _category == c
                                  ? appColors.white
                                  : appColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      FilterChip(
                        label: const Text('More filters'),
                        avatar: const Icon(Icons.tune, size: 18),
                        selected: hasAdvanced,
                        onSelected: (_) => _openFiltersSheet(),
                        selectedColor: appColors.primaryPurple.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              data: (OriRecordResults results) {
                if (results.records.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No records match the current filters.'
                            : 'No results for "$_searchQuery"',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: results.records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext ctx, int i) {
                    final OriRecord r = results.records[i];
                    return _OriRecordTile(record: r);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load records: $e',
                    style: Theme.of(context).textTheme.bodyMedium,
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
}

class _OriRecordTile extends StatelessWidget {
  const _OriRecordTile({required this.record});

  final OriRecord record;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final String parties = <String?>[record.fromParty, record.toParty]
        .whereType<String>()
        .where((String s) => s.isNotEmpty)
        .join(' → ');
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.pushNamed(
          RouteNames.oriRecordDetail,
          extra: record,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: appColors.lightPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      record.transactionDisplay,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: appColors.primaryPurple,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    record.fileDateString,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: appColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (parties.isNotEmpty)
                Text(
                  parties.toUpperCase(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (record.description != null &&
                  record.description!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  record.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: appColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${record.bookPageDisplay} · #${record.instrumentNumber}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: appColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheetResult {
  _FilterSheetResult({
    required this.codes,
    required this.startDate,
    required this.endDate,
  });

  final List<String> codes;
  final DateTime? startDate;
  final DateTime? endDate;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initialCodes,
    required this.startDate,
    required this.endDate,
  });

  final List<String> initialCodes;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<String> _selected;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCodes.toSet();
    _start = widget.startDate;
    _end = widget.endDate;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime initial = (isStart ? _start : _end) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1983),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = transactionCodeLabels.entries.toList()
      ..sort((MapEntry<String, String> a, MapEntry<String, String> b) =>
          a.value.compareTo(b.value));
    final MediaQueryData mq = MediaQuery.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    const Text(
                      'Filters',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selected.clear();
                          _start = null;
                          _end = null;
                        });
                      },
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        onPressed: () => _pickDate(isStart: true),
                        label: Text(_start == null
                            ? 'Start date'
                            : '${_start!.month}/${_start!.day}/${_start!.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        onPressed: () => _pickDate(isStart: false),
                        label: Text(_end == null
                            ? 'End date'
                            : '${_end!.month}/${_end!.day}/${_end!.year}'),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding:
                    EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Transaction types',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: entries.length,
                  itemBuilder: (BuildContext _, int i) {
                    final MapEntry<String, String> e = entries[i];
                    final bool on = _selected.contains(e.key);
                    return CheckboxListTile(
                      dense: true,
                      value: on,
                      onChanged: (bool? v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(e.key);
                          } else {
                            _selected.remove(e.key);
                          }
                        });
                      },
                      title: Text(e.value),
                      subtitle: Text(e.key),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _FilterSheetResult(
                          codes: _selected.toList(),
                          startDate: _start,
                          endDate: _end,
                        ),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
