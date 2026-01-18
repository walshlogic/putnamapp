import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/booking.dart';
import '../models/booking_filters.dart';
import '../providers/booking_providers.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/bookings/booking_list_item.dart';
import '../widgets/bookings/bookings_status_bar.dart';
import '../widgets/bookings/search_panel.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = AppConfig.statusAll;
  String _selectedTimeFilter = AppConfig.timeRange24Hours;
  SortField _sortBy = SortField.date;
  SortDirection _sortDirection = SortDirection.descending;
  
  // Pagination state
  List<JailBooking> _allLoadedBookings = <JailBooking>[];
  int _currentOffset = 0;
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
    
    // Wait before actually searching
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

  // Get current filters
  BookingFilters _getCurrentFilters({int? offset}) {
    return BookingFilters(
      timeRange: _selectedTimeFilter,
      status: _selectedFilter,
      searchQuery: _searchQuery,
      sortBy: _sortBy,
      sortDirection: _sortDirection,
      offset: offset ?? _currentOffset,
      limit: AppConfig.defaultPageSize,
    );
  }

  // Reset pagination when filters change
  void _resetPagination() {
    setState(() {
      _allLoadedBookings.clear();
      _currentOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    
    // Watch the filtered bookings with current filters
    final AsyncValue<BookingResults> bookingResults = ref.watch(
      filteredBookingsProvider(_getCurrentFilters()),
    );

    // Get keyboard height to adjust layout
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardVisible = keyboardHeight > 0;
    
    // Calculate max height for search panel based on keyboard visibility
    // When keyboard is visible, use much smaller height to prevent overflow
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
                    child: SearchPanel(
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
                      ref.invalidate(filteredBookingsProvider);
                      setState(() {
                        _selectedTimeFilter = value;
                        _isChangingFilters = true;
                      });
                    },
                    selectedStatusFilter: _selectedFilter,
                    onStatusFilterChanged: (String value) {
                      _resetPagination();
                      ref.invalidate(filteredBookingsProvider);
                      setState(() {
                        _selectedFilter = value;
                        _isChangingFilters = true;
                      });
                    },
                    currentSortField: _sortBy,
                    currentSortDirection: _sortDirection,
                    onSortChanged: (SortField field, SortDirection direction) {
                      _resetPagination();
                      ref.invalidate(filteredBookingsProvider);
                      setState(() {
                        _sortBy = field;
                        _sortDirection = direction;
                        _isChangingFilters = true;
                      });
                    },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          
          // Fixed Status Bar (pinned, visible only when keyboard is hidden)
          if (!isKeyboardVisible)
            bookingResults.when(
              data: (BookingResults results) {
                // When offset is 0, use fresh results and update cache
                if (_currentOffset == 0 && _allLoadedBookings != results.bookings) {
                  // Update cache after frame to avoid setState during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _allLoadedBookings = results.bookings;
                      });
                    }
                  });
                }
                
                final List<JailBooking> displayBookings = 
                  _currentOffset == 0 ? results.bookings : _allLoadedBookings;
                
                if (displayBookings.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return BookingsStatusBar(
                  displayCount: displayBookings.length,
                  totalCount: results.totalCount,
                  timeFilter: _selectedTimeFilter,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (Object e, StackTrace st) => const SizedBox.shrink(),
            ),
          
          // Bookings List (scrollable)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _resetPagination();
                ref.invalidate(filteredBookingsProvider);
                setState(() {
                  _isChangingFilters = true;
                });
              },
              child: bookingResults.when(
                data: (BookingResults results) {
                  // When offset is 0, use fresh results and update cache
                  if (_currentOffset == 0 && _allLoadedBookings != results.bookings) {
                    // Update cache after frame to avoid setState during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _allLoadedBookings = results.bookings;
                          _isChangingFilters = false; // Reset flag after successful load
                        });
                      }
                    });
                  }
                  
                  final List<JailBooking> displayBookings = 
                    _currentOffset == 0 ? results.bookings : _allLoadedBookings;
                  
                  // Show loading spinner when changing filters
                  if (_isChangingFilters && displayBookings.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (displayBookings.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'NO RESULTS FOUND'
                              : 'NO RECENT BOOKINGS',
                        ),
                      ),
                      );
                  }

                  return ResponsiveUtils.constrainWidth(
                    context,
                    ListView(
                      padding: context.responsivePadding,
                      children: <Widget>[
                      // Booking cards
                      ...displayBookings.map((JailBooking b) {
                        return BookingListItem(
                          booking: b,
                          onTap: () =>
                              context.push(RoutePaths.bookingDetail, extra: b),
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
                                  final int nextOffset = _currentOffset + AppConfig.defaultPageSize;
                                  final BookingResults moreResults = await ref.read(
                                    filteredBookingsProvider(
                                      _getCurrentFilters(offset: nextOffset),
                                    ).future,
                                  );
                                  
                                  setState(() {
                                    _allLoadedBookings.addAll(moreResults.bookings);
                                    _currentOffset = nextOffset;
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
                                'LOAD MORE (${_formatNumber(results.totalCount - displayBookings.length)} REMAINING)',
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
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load bookings: $e',
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
