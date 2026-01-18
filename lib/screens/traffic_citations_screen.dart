import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../config/route_names.dart';
import '../extensions/build_context_extensions.dart';
import '../models/traffic_citation.dart';
import '../models/traffic_citation_filters.dart';
import '../providers/traffic_citation_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/traffic_citations/traffic_citation_list_item.dart';
import '../widgets/traffic_citations/traffic_citation_search_panel.dart';
import '../widgets/traffic_citations/traffic_citation_status_bar.dart';

class TrafficCitationsScreen extends ConsumerStatefulWidget {
  const TrafficCitationsScreen({super.key});

  @override
  ConsumerState<TrafficCitationsScreen> createState() =>
      _TrafficCitationsScreenState();
}

class _TrafficCitationsScreenState
    extends ConsumerState<TrafficCitationsScreen> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTimeFilter = AppConfig.timeRangeThisYear;
  String? _selectedCity;
  String? _selectedViolationType;
  String _sortBy = AppConfig.sortByDate;
  String _sortOrder = AppConfig.sortOrderDesc;
  String _nameSortBy = AppConfig.nameSortByLastName;
  int _currentPage = 1;
  final int _pageSize = 50;

  // Pagination state (accumulate citations as pages load)
  List<TrafficCitation> _allLoadedCitations = <TrafficCitation>[];
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

  TrafficCitationFilters _getCurrentFilters({int? page}) {
    return TrafficCitationFilters(
      timeRange: _selectedTimeFilter,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      city: _selectedCity,
      violationType: _selectedViolationType,
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
      _allLoadedCitations.clear();
      _currentPage = 1;
    });
  }


  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    
    // Watch the filtered citations with current filters
    final AsyncValue<TrafficCitationResults> citationResults = ref.watch(
      trafficCitationsProvider(_getCurrentFilters()),
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
                    child: TrafficCitationSearchPanel(
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
                      ref.invalidate(trafficCitationsProvider);
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
                      ref.invalidate(trafficCitationsProvider);
                      setState(() {
                        _sortBy = value;
                        _isChangingFilters = true;
                      });
                    },
                    onSortOrderChanged: (String value) {
                      _resetPagination();
                      ref.invalidate(trafficCitationsProvider);
                      setState(() {
                        _sortOrder = value;
                        _isChangingFilters = true;
                      });
                    },
                    onNameSortByChanged: (String value) {
                      _resetPagination();
                      ref.invalidate(trafficCitationsProvider);
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
            citationResults.when(
              data: (TrafficCitationResults results) {
                // When page is 1, use fresh results and update cache
                if (_currentPage == 1 && _allLoadedCitations != results.citations) {
                  // Update cache after frame to avoid setState during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _allLoadedCitations = results.citations;
                      });
                    }
                  });
                }
                
                final List<TrafficCitation> displayCitations = 
                  _currentPage == 1 ? results.citations : _allLoadedCitations;
                
                if (displayCitations.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return TrafficCitationStatusBar(
                  displayCount: displayCitations.length,
                  totalCount: results.totalCount,
                  timeFilter: _selectedTimeFilter,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (Object e, StackTrace st) => const SizedBox.shrink(),
            ),
          
          // Citations List (scrollable)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _resetPagination();
                ref.invalidate(trafficCitationsProvider);
                setState(() {
                  _isChangingFilters = true;
                });
              },
              child: citationResults.when(
                data: (TrafficCitationResults results) {
                  // When page is 1, use fresh results and update cache
                  if (_currentPage == 1 && _allLoadedCitations != results.citations) {
                    // Update cache after frame to avoid setState during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _allLoadedCitations = results.citations;
                          _isChangingFilters = false; // Reset flag after successful load
                        });
                      }
                    });
                  }
                  
                  final List<TrafficCitation> displayCitations = 
                    _currentPage == 1 ? results.citations : _allLoadedCitations;
                  
                  // Show loading spinner when changing filters
                  if (_isChangingFilters && displayCitations.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (displayCitations.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'NO RESULTS FOUND'
                              : 'NO CITATIONS FOUND',
                        ),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      // Citation cards
                      ...displayCitations.map((TrafficCitation c) {
                        return TrafficCitationListItem(
                          citation: c,
                          onTap: () =>
                              context.pushNamed(
                                RouteNames.trafficCitationDetail,
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
                                  final TrafficCitationResults moreResults = await ref.read(
                                    trafficCitationsProvider(
                                      _getCurrentFilters(page: nextPage),
                                    ).future,
                                  );
                                  
                                  setState(() {
                                    _allLoadedCitations.addAll(moreResults.citations);
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
                                'LOAD MORE (${_formatNumber(results.totalCount - displayCitations.length)} REMAINING)',
                                style: TextStyle(color: appColors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColors.primaryPurple,
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
                      'Failed to load citations: $e',
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
