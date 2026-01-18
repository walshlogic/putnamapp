import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/place.dart';
import '../models/place_filters.dart';
import '../providers/directory_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/places/place_search_panel.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/reviews/star_rating_display.dart';
import '../widgets/settings_drawer.dart';

/// Screen to display list of places in a category
class PlaceListScreen extends ConsumerStatefulWidget {
  const PlaceListScreen({
    required this.category,
    super.key,
  });

  final PlaceCategory category;

  @override
  ConsumerState<PlaceListScreen> createState() => _PlaceListScreenState();
}

class _PlaceListScreenState extends ConsumerState<PlaceListScreen> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  late PlaceFilters _filters;
  
  // Search debounce timer
  DateTime _lastSearchUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _filters = PlaceFilters(
      category: widget.category.value,
      sortBy: PlaceSortField.rating,
      sortDirection: PlaceSortDirection.descending,
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
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_lastSearchUpdate == now && mounted) {
        setState(() {
          _filters = _filters.copyWith(searchQuery: value);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    
    // Watch the filtered places
    final placesAsync = ref.watch(filteredPlacesProvider(_filters));
    
    // Watch available subcategories for this category
    final subcategoriesAsync = ref.watch(
      subcategoriesProvider(widget.category.value),
    );

    // Get keyboard height to adjust layout
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardVisible = keyboardHeight > 0;
    
    // Calculate max height for search panel
    final double searchPanelMaxHeight = isKeyboardVisible ? 150.0 : 500.0;

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: <Widget>[
          // Category Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getCategoryColors(appColors),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  _getCategoryIcon(),
                  color: appColors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.category.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: appColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.category.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: appColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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
                    child: subcategoriesAsync.when(
                      data: (subcategories) => PlaceSearchPanel(
                        searchController: _searchController,
                        onSearchChanged: _onSearchChanged,
                        onSearchCleared: () {
                          _searchController.clear();
                          setState(() {
                            _filters = _filters.copyWith(searchQuery: '');
                          });
                        },
                        currentFilters: _filters,
                        onFiltersChanged: (newFilters) {
                          setState(() {
                            _filters = newFilters;
                          });
                        },
                        availableSubcategories: subcategories,
                        onSortChanged: (field, direction) {
                          setState(() {
                            _filters = _filters.copyWith(
                              sortBy: field,
                              sortDirection: direction,
                            );
                          });
                        },
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => PlaceSearchPanel(
                        searchController: _searchController,
                        onSearchChanged: _onSearchChanged,
                        onSearchCleared: () {
                          _searchController.clear();
                          setState(() {
                            _filters = _filters.copyWith(searchQuery: '');
                          });
                        },
                        currentFilters: _filters,
                        onFiltersChanged: (newFilters) {
                          setState(() {
                            _filters = newFilters;
                          });
                        },
                        availableSubcategories: const <String>[],
                        onSortChanged: (field, direction) {
                          setState(() {
                            _filters = _filters.copyWith(
                              sortBy: field,
                              sortDirection: direction,
                            );
                          });
                        },
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Results count bar (when not searching)
          if (!isKeyboardVisible)
            placesAsync.when(
              data: (places) {
                if (places.isEmpty) return const SizedBox.shrink();
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: appColors.scaffoldBackground,
                  child: Text(
                    '${places.length} ${places.length == 1 ? 'PLACE' : 'PLACES'} FOUND',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: appColors.textLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          // Place List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(filteredPlacesProvider);
              },
              child: placesAsync.when(
                data: (places) {
                  if (places.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              _getCategoryIcon(),
                              size: 64,
                              color: appColors.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filters.searchQuery.isNotEmpty ||
                                      _filters.subcategories.isNotEmpty ||
                                      _filters.priceRanges.isNotEmpty
                                  ? 'NO MATCHES FOUND'
                                  : 'NO PLACES YET',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: appColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _filters.searchQuery.isNotEmpty ||
                                      _filters.subcategories.isNotEmpty ||
                                      _filters.priceRanges.isNotEmpty
                                  ? 'Try adjusting your filters'
                                  : 'Check back soon for ${widget.category.displayName.toLowerCase()} listings!',
                              style: TextStyle(
                                fontSize: 14,
                                color: appColors.textLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return _buildPlaceCard(context, appColors, place);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: appColors.accentPink,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ERROR LOADING PLACES',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: appColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textLight,
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

  Widget _buildPlaceCard(BuildContext context, dynamic appColors, Place place) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(RoutePaths.placeDetail, extra: place);
        },
        borderRadius: BorderRadius.circular(12),
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Icon/Photo placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getCategoryColors(appColors),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: appColors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),

                // Place Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Name
                      Text(
                        place.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: appColors.textDark,
                        ),
                      ),
                      
                      // Subcategory badge
                      if (place.subcategory != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: appColors.lightPurple.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: appColors.primaryPurple.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            place.subcategory!.toUpperCase().replaceAll('-', ' '),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: appColors.primaryPurple,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),

                      // Rating
                      if (place.reviewCount > 0) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            StarRatingDisplay(
                              rating: place.averageRating,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${place.averageRating.toStringAsFixed(1)} (${place.reviewCount})',
                              style: TextStyle(
                                fontSize: 12,
                                color: appColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Address
                      if (place.address != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: appColors.textLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: appColors.textLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Price range
                      if (place.priceRange != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          place.priceRange!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: appColors.accentTeal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Icons.chevron_right,
                  color: appColors.divider,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getCategoryColors(dynamic appColors) {
    switch (widget.category) {
      case PlaceCategory.restaurant:
        return <Color>[appColors.accentPink, appColors.accentPinkDark];
      case PlaceCategory.retail:
        return <Color>[appColors.accentTeal, appColors.accentTealDark];
      case PlaceCategory.faith:
        return <Color>[appColors.primaryPurple, appColors.darkPurple];
      case PlaceCategory.entertainment:
        return <Color>[appColors.accentOrange, appColors.accentOrangeDark];
      case PlaceCategory.lodging:
        return <Color>[appColors.accentPink, appColors.accentPinkDark];
      case PlaceCategory.services:
        return <Color>[appColors.accentTeal, appColors.accentTealDark];
      case PlaceCategory.health:
        return <Color>[appColors.primaryPurple, appColors.darkPurple];
      case PlaceCategory.business:
        return <Color>[appColors.accentOrange, appColors.accentOrangeDark];
      case PlaceCategory.outdoors:
        return <Color>[appColors.primaryPurple, appColors.darkPurple];
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.category) {
      case PlaceCategory.restaurant:
        return Icons.restaurant;
      case PlaceCategory.retail:
        return Icons.shopping_bag;
      case PlaceCategory.faith:
        return Icons.church;
      case PlaceCategory.entertainment:
        return Icons.theater_comedy;
      case PlaceCategory.lodging:
        return Icons.hotel;
      case PlaceCategory.services:
        return Icons.build;
      case PlaceCategory.health:
        return Icons.local_hospital;
      case PlaceCategory.business:
        return Icons.business_center;
      case PlaceCategory.outdoors:
        return Icons.phishing;
    }
  }
}
