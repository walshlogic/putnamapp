import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../config/route_names.dart';
import '../extensions/build_context_extensions.dart';
import '../models/criminal_back_history.dart';
import '../models/criminal_back_history_filters.dart';
import '../providers/criminal_back_history_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/criminal_back_history/criminal_back_history_list_item.dart';
import '../widgets/criminal_back_history/criminal_back_history_search_panel.dart';
import '../widgets/criminal_back_history/criminal_back_history_status_bar.dart';

class CriminalBackHistoryScreen extends ConsumerStatefulWidget {
  const CriminalBackHistoryScreen({super.key});

  @override
  ConsumerState<CriminalBackHistoryScreen> createState() =>
      _CriminalBackHistoryScreenState();
}

class _CriminalBackHistoryScreenState
    extends ConsumerState<CriminalBackHistoryScreen> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTimeFilter = AppConfig.timeRangeThisYear;
  String _sortBy = AppConfig.sortByDate;
  String _sortOrder = AppConfig.sortOrderDesc;
  String _nameSortBy = AppConfig.nameSortByLastName;
  int _currentPage = 1;
  final int _pageSize = 50;

  // Pagination state (accumulate cases as pages load)
  List<CriminalBackHistory> _allLoadedCases = <CriminalBackHistory>[];
  bool _isLoadingMore = false;
  bool _isChangingFilters = false;

  // Search debounce timer
  DateTime _lastSearchUpdate = DateTime.now();

  /// Format number with comma separators
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Handle search with debounce
  void _onSearchChanged(String value) {
    final DateTime now = DateTime.now();
    _lastSearchUpdate = now;

    Future.delayed(AppConfig.searchDebounceDelay, () {
      if (_lastSearchUpdate == now && mounted) {
        _resetPagination();
        setState(() {
          _searchQuery = value;
          _isChangingFilters = true;
        });
      }
    });
  }

  CriminalBackHistoryFilters _getCurrentFilters({int? page}) {
    return CriminalBackHistoryFilters(
      timeRange: _selectedTimeFilter,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
      nameSortBy: _nameSortBy,
      page: page ?? _currentPage,
      pageSize: _pageSize,
    );
  }

  // Reset pagination when filters change
  void _resetPagination() {
    setState(() {
      _allLoadedCases.clear();
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    
    // Watch the filtered cases with current filters
    final AsyncValue<CriminalBackHistoryResults> caseResults = ref.watch(
      criminalBackHistoryProvider(_getCurrentFilters()),
    );

    // Get keyboard height to adjust layout
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardVisible = keyboardHeight > 0;
    
    // Calculate max height for search panel based on keyboard visibility
    final double searchPanelMaxHeight = isKeyboardVisible ? 150.0 : 400.0;

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
                    child: CriminalBackHistorySearchPanel(
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onSearchCleared: () {
                      _searchController.clear();
                      _resetPagination();
                      setState(() {
                        _searchQuery = '';
                        _isChangingFilters = true;
                      });
                    },
                    selectedTimeFilter: _selectedTimeFilter,
                    onTimeFilterChanged: (String value) {
                      _resetPagination();
                      ref.invalidate(criminalBackHistoryProvider);
                      setState(() {
                        _selectedTimeFilter = value;
                        _isChangingFilters = true;
                      });
                    },
                    sortBy: _sortBy,
                    sortOrder: _sortOrder,
                    nameSortBy: _nameSortBy,
                    onSortByChanged: (String value) {
                      _resetPagination();
                      ref.invalidate(criminalBackHistoryProvider);
                      setState(() {
                        _sortBy = value;
                        _isChangingFilters = true;
                      });
                    },
                    onSortOrderChanged: (String value) {
                      _resetPagination();
                      ref.invalidate(criminalBackHistoryProvider);
                      setState(() {
                        _sortOrder = value;
                        _isChangingFilters = true;
                      });
                    },
                    onNameSortByChanged: (String value) {
                      _resetPagination();
                      ref.invalidate(criminalBackHistoryProvider);
                      setState(() {
                        _nameSortBy = value;
                        _isChangingFilters = true;
                      });
                    },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          
          // Fixed Status Bar (pinned, visible only when keyboard is hidden)
          if (!isKeyboardVisible)
            caseResults.when(
              data: (CriminalBackHistoryResults results) {
                // When page is 1, use fresh results and update cache
                if (_currentPage == 1 && _allLoadedCases != results.cases) {
                  // Update cache after frame to avoid setState during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _allLoadedCases = results.cases;
                      });
                    }
                  });
                }
                
                final List<CriminalBackHistory> displayCases = 
                  _currentPage == 1 ? results.cases : _allLoadedCases;
                
                if (displayCases.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return CriminalBackHistoryStatusBar(
                  displayCount: displayCases.length,
                  totalCount: results.totalCount,
                  timeFilter: _selectedTimeFilter,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (Object e, StackTrace st) => const SizedBox.shrink(),
            ),
          
          // Cases List (scrollable)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _resetPagination();
                ref.invalidate(criminalBackHistoryProvider);
                setState(() {
                  _isChangingFilters = true;
                });
              },
              child: caseResults.when(
                data: (CriminalBackHistoryResults results) {
                  // When page is 1, use fresh results and update cache
                  if (_currentPage == 1 && _allLoadedCases != results.cases) {
                    // Update cache after frame to avoid setState during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _allLoadedCases = results.cases;
                          _isChangingFilters = false; // Reset flag after successful load
                        });
                      }
                    });
                  }
                  
                  final List<CriminalBackHistory> displayCases = 
                    _currentPage == 1 ? results.cases : _allLoadedCases;
                  
                  // Show loading spinner when changing filters
                  if (_isChangingFilters && displayCases.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (displayCases.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'NO RESULTS FOUND'
                              : 'NO CASES FOUND',
                        ),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      // Case cards
                      ...displayCases.map((CriminalBackHistory c) {
                        return CriminalBackHistoryListItem(
                          caseRecord: c,
                          onTap: () =>
                              context.pushNamed(
                                RouteNames.criminalBackHistoryDetail,
                                extra: c,
                              ),
                        );
                      }),
                      // Load More button
                      if (results.hasMore && !_isLoadingMore)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                setState(() {
                                  _isLoadingMore = true;
                                });
                                
                                try {
                                  // Load next page
                                  final int nextPage = _currentPage + 1;
                                  final CriminalBackHistoryResults moreResults = await ref.read(
                                    criminalBackHistoryProvider(
                                      _getCurrentFilters(page: nextPage),
                                    ).future,
                                  );
                                  
                                  setState(() {
                                    _allLoadedCases.addAll(moreResults.cases);
                                    _currentPage = nextPage;
                                    _isLoadingMore = false;
                                  });
                                } catch (e) {
                                  setState(() {
                                    _isLoadingMore = false;
                                  });
                                }
                              },
                              icon: Icon(Icons.add, color: appColors.white),
                              label: Text(
                                'LOAD MORE (${_formatNumber(results.totalCount - displayCases.length)} REMAINING)',
                                style: TextStyle(color: appColors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColors.accentOrange,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load cases: $e',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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

