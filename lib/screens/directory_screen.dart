import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/place.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

/// Local Directory screen - main hub for discovering local places
class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final padding = context.responsivePadding;

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ResponsiveUtils.constrainWidth(
              context,
              ListView(
                padding: padding,
              children: <Widget>[
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        appColors.accentTeal,
                        appColors.accentTealDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.location_on,
                            color: appColors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'LOCAL PLACES',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: appColors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Discover Putnam County',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: appColors.white.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for places...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: appColors.textLight,
                    ),
                    prefixIcon: Icon(Icons.search, color: appColors.accentTeal),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: appColors.scaffoldBackground,
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
                const SizedBox(height: 24),

                // Categories Label
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'BROWSE BY CATEGORY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: appColors.textDark,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                // Category Grid
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: PlaceCategory.values.map((category) {
                    return _buildCategoryCard(context, appColors, category);
                  }).toList(),
                ),
              ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    dynamic appColors,
    PlaceCategory category,
  ) {
    // Get gradient colors and icon for each category
    final colors = _getCategoryColors(appColors, category);
    final icon = _getCategoryIcon(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(RoutePaths.directoryCategory, extra: category);
        },
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive sizes based on available space
                final buttonWidth = constraints.maxWidth;
                final buttonHeight = constraints.maxHeight;
                final minDimension = buttonWidth < buttonHeight
                    ? buttonWidth
                    : buttonHeight;

                // Icon size: 28% of minimum dimension
                final iconSize = minDimension * 0.28;
                // Font size: 6.5% of minimum dimension
                final fontSize = minDimension * 0.065;
                // Gap: 7% of minimum dimension
                final gap = minDimension * 0.07;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Icon
                    Icon(icon, size: iconSize, color: appColors.white),
                    SizedBox(height: gap),
                    // Category Name
                    Text(
                      category.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: appColors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Get gradient colors for each category
  List<Color> _getCategoryColors(dynamic appColors, PlaceCategory category) {
    switch (category) {
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

  /// Get icon for each category
  IconData _getCategoryIcon(PlaceCategory category) {
    switch (category) {
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
        return Icons.phishing; // Fish icon for outdoors
    }
  }
}
