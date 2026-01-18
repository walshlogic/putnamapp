import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/sex_offender.dart';
import '../models/sex_offender_filters.dart';
import '../providers/sex_offender_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/offenders/offender_search_panel.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class SexOffenderScreen extends ConsumerStatefulWidget {
  const SexOffenderScreen({super.key});

  @override
  ConsumerState<SexOffenderScreen> createState() => _SexOffenderScreenState();
}

class _SexOffenderScreenState extends ConsumerState<SexOffenderScreen> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  SexOffenderFilters _filters = SexOffenderFilters();

  // Search debounce timer
  DateTime _lastSearchUpdate = DateTime.now();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Handle search with debounce
  void _onSearchChanged(String value) {
    final DateTime now = DateTime.now();
    _lastSearchUpdate = now;

    // Wait before actually searching
    Future.delayed(AppConfig.searchDebounceDelay, () {
      if (_lastSearchUpdate == now && mounted) {
        setState(() {
          _filters = _filters.copyWith(searchQuery: value);
        });
      }
    });
  }

  void _closeSearchPanel() {
    setState(() {
      _isSearchExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final offenders = ref.watch(filteredOffendersProvider(_filters));

    // Get keyboard height to adjust layout
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardVisible = keyboardHeight > 0;

    // Calculate max height for search panel based on keyboard visibility
    final double searchPanelMaxHeight = isKeyboardVisible ? 200.0 : 500.0;

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: <Widget>[
          // Search/Filter Toggle Tab
          Material(
            color: appColors.lightPurple,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isSearchExpanded = !_isSearchExpanded;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.search,
                      color: appColors.primaryPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isSearchExpanded ? 'HIDE SEARCH & FILTERS' : 'SEARCH & FILTERS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: appColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isSearchExpanded ? Icons.expand_less : Icons.expand_more,
                      color: appColors.primaryPurple,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Animated Search Panel
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSearchExpanded ? null : 0,
            constraints: _isSearchExpanded
                ? BoxConstraints(maxHeight: searchPanelMaxHeight)
                : const BoxConstraints(maxHeight: 0),
            child: _isSearchExpanded
                ? SingleChildScrollView(
                    child: OffenderSearchPanel(
                      searchController: _searchController,
                      onSearchChanged: _onSearchChanged,
                      onSearchCleared: () {
                        _searchController.clear();
                        setState(() {
                          _filters = _filters.copyWith(searchQuery: '');
                        });
                      },
                      selectedCity: _filters.selectedCity,
                      onCityChanged: (String? city) {
                        setState(() {
                          _filters = _filters.copyWith(selectedCity: city);
                        });
                        _closeSearchPanel();
                      },
                      currentSortField: _filters.sortBy,
                      currentSortDirection: _filters.sortDirection,
                      onSortChanged: (SortField field, SortDirection direction) {
                        setState(() {
                          _filters = _filters.copyWith(
                            sortBy: field,
                            sortDirection: direction,
                          );
                        });
                        _closeSearchPanel();
                      },
                      onClose: _closeSearchPanel,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Offenders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(filteredOffendersProvider);
              },
              child: offenders.when(
                data: (List<SexOffender> data) {
                  if (data.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _filters.hasActiveFilters
                              ? 'NO RESULTS FOUND'
                              : 'NO OFFENDERS FOUND',
                          style: TextStyle(
                            color: appColors.textMedium,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  final styles = context.personCardStyles;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      ...data.map((SexOffender o) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              context.push(
                                RoutePaths.sexOffenderDetail,
                                extra: o,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  // Photo or placeholder
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: appColors.lightPurple,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: appColors.primaryPurple.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: o.imageUrl != null && o.imageUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(11),
                                            child: Image.network(
                                              o.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.person_outline,
                                                color: appColors.primaryPurple,
                                                size: 32,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.person_outline,
                                            color: appColors.primaryPurple,
                                            size: 32,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          o.name.toUpperCase(),
                                          style: styles.nameStyle.copyWith(
                                            color: appColors.textDark,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: <Widget>[
                                            Icon(
                                              Icons.location_city,
                                              size: 14,
                                              color: appColors.textMedium,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              o.city.toUpperCase(),
                                              style: styles.detailStyle.copyWith(
                                                color: appColors.textMedium,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (o.birthDate != null) ...<Widget>[
                                              const SizedBox(width: 12),
                                              Icon(
                                                Icons.cake,
                                                size: 14,
                                                color: appColors.textMedium,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'AGE ${o.age}',
                                                style: styles.detailStyle.copyWith(
                                                  color: appColors.textMedium,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (o.status != null && o.status!.isNotEmpty) ...<Widget>[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: appColors.accentOrange.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              o.status!.toUpperCase(),
                                              style: TextStyle(
                                                color: appColors.accentOrange,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: appColors.divider,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'FAILED TO LOAD OFFENDERS',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.toString(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
