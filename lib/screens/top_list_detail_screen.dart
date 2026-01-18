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
  String _selectedTimeFilter = 'THISYEAR';

  @override
  void initState() {
    super.initState();
    // Ensure selected filter is valid for this category
    _validateTimeFilter();
  }

  /// Validate that the selected time filter is available for this category
  void _validateTimeFilter() {
    final bool includeAllDates = widget.category == TopListCategory.arrestedPersons ||
        widget.category == TopListCategory.bookingDays;
    
    // If category doesn't support ALL and ALL is selected, reset to THISYEAR
    if (!includeAllDates && _selectedTimeFilter == 'ALL') {
      _selectedTimeFilter = 'THISYEAR';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    // Ensure filter is still valid (in case category changed)
    _validateTimeFilter();

    // Get the appropriate provider based on category and time filter
    final AsyncValue<List<TopListItem>> topListAsync = _getProviderForCategory(_selectedTimeFilter);

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  appColors.accentPink,
                  appColors.accentPinkDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.emoji_events,
                      color: appColors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.category.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: appColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.category.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: appColors.white.withValues(alpha: 0.9),
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

          // Time Filter Dropdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: appColors.lightPurple,
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.filter_list,
                  size: 20,
                  color: appColors.primaryPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  'TIME RANGE:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: appColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedTimeFilter,
                    isExpanded: true,
                    underline: Container(),
                    dropdownColor: appColors.cardBackground,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: appColors.textDark,
                    ),
                    items: _getTimeFilterItems(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedTimeFilter = value;
                        });
                        // Invalidate provider to refetch with new filter
                        ref.invalidate(topArrestedPersonsProvider);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // List Content
          Expanded(
            child: topListAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'NO DATA AVAILABLE',
                        style: TextStyle(
                          fontSize: 16,
                          color: appColors.textLight,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildListItem(context, appColors, item, widget.category);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                        'ERROR LOADING DATA',
                        style: TextStyle(
                          fontSize: 16,
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
          const AppFooter(),
        ],
      ),
    );
  }

  /// Get the appropriate provider based on category and time filter
  AsyncValue<List<TopListItem>> _getProviderForCategory(String timeFilter) {
    // Convert filter string to time_range format
    final String timeRange = timeFilter; // Already in correct format: THISYEAR, 5YEARS, ALL
    
    switch (widget.category) {
      case TopListCategory.arrestedPersons:
        return ref.watch(topArrestedPersonsProvider(timeRange));
      case TopListCategory.felonyCharges:
        return ref.watch(topFelonyChargesProvider(timeRange));
      case TopListCategory.misdemeanorCharges:
        return ref.watch(topMisdemeanorChargesProvider(timeRange));
      case TopListCategory.allCharges:
        return ref.watch(topAllChargesProvider(timeRange));
      case TopListCategory.bookingDays:
        return ref.watch(topBookingDaysProvider(timeRange));
    }
  }

  Widget _buildListItem(
    BuildContext context,
    dynamic appColors,
    TopListItem item,
    TopListCategory category,
  ) {
    // Make cards clickable for all categories except none
    final bool isClickable = true;

    Widget cardContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          // Rank Badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getRankColor(item.rank, appColors),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#${item.rank}',
                style: TextStyle(
                  fontSize: _getRankFontSize(item.rank),
                  fontWeight: FontWeight.bold,
                  color: appColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Label and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: appColors.textDark,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                item.formattedCount,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: appColors.primaryPurple,
                ),
              ),
              Text(
                category.countLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: appColors.textLight,
                ),
              ),
            ],
          ),
          // Show chevron if clickable
          if (isClickable) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: appColors.textLight,
              size: 20,
            ),
          ],
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _handleCardTap(context, item, category);
        },
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      ),
    );
  }

  void _handleCardTap(
    BuildContext context,
    TopListItem item,
    TopListCategory category,
  ) {
    switch (category) {
      case TopListCategory.arrestedPersons:
        // Navigate to charge breakdown for person
        context.push(
          RoutePaths.personChargeBreakdown,
          extra: item.label,
        );
        break;
      case TopListCategory.felonyCharges:
      case TopListCategory.misdemeanorCharges:
      case TopListCategory.allCharges:
        // Navigate to people charged with this charge
        context.push(
          RoutePaths.peopleByCharge,
          extra: {
            'chargeName': item.label,
            'timeRange': _selectedTimeFilter,
          },
        );
        break;
      case TopListCategory.bookingDays:
        // Navigate to bookings for this date
        // Parse date from label (format may vary, try common formats)
        try {
          // Try parsing date - label might be in format like "2024-01-15" or "01/15/2024"
          DateTime? bookingDate;
          if (item.label.contains('-')) {
            bookingDate = DateTime.tryParse(item.label);
          } else if (item.label.contains('/')) {
            final parts = item.label.split('/');
            if (parts.length == 3) {
              final month = int.tryParse(parts[0]);
              final day = int.tryParse(parts[1]);
              final year = int.tryParse(parts[2]);
              if (month != null && day != null && year != null) {
                bookingDate = DateTime(year, month, day);
              }
            }
          }
          
          if (bookingDate != null) {
            context.push(
              RoutePaths.bookingsByDate,
              extra: bookingDate,
            );
          }
        } catch (e) {
          // If date parsing fails, do nothing
        }
        break;
    }
  }

  /// Get color based on rank (gold, silver, bronze for top 3)
  Color _getRankColor(int rank, dynamic appColors) {
    if (rank == 1) {
      return const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      return const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      return const Color(0xFFCD7F32); // Bronze
    } else {
      return appColors.primaryPurple;
    }
  }

  /// Get font size based on rank (smaller for 3-digit numbers like #100)
  double _getRankFontSize(int rank) {
    if (rank >= 100) {
      return 11.0; // Smaller for 3-digit ranks (#100)
    } else if (rank >= 10) {
      return 14.0; // Standard for 2-digit ranks (#10-99)
    } else {
      return 16.0; // Larger for single-digit ranks (#1-9)
    }
  }

  /// Get time filter items based on category
  /// For charge categories (felony, misdemeanor, all charges), exclude "ALL DATES"
  List<DropdownMenuItem<String>> _getTimeFilterItems() {
    final bool includeAllDates = widget.category == TopListCategory.arrestedPersons ||
        widget.category == TopListCategory.bookingDays;

    if (includeAllDates) {
      return const <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'THISYEAR', child: Text('THIS YEAR')),
        DropdownMenuItem(value: '5YEARS', child: Text('PAST 5 YEARS')),
        DropdownMenuItem(value: 'ALL', child: Text('ALL DATES')),
      ];
    } else {
      // For felony, misdemeanor, and all charges - only show THIS YEAR and PAST 5 YEARS
      return const <DropdownMenuItem<String>>[
        DropdownMenuItem(value: 'THISYEAR', child: Text('THIS YEAR')),
        DropdownMenuItem(value: '5YEARS', child: Text('PAST 5 YEARS')),
      ];
    }
  }
}

