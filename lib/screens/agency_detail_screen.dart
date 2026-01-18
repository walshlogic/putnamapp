import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../extensions/build_context_extensions.dart';
import '../models/agency.dart';
import '../providers/agency_stats_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

/// Agency Detail screen showing statistics for a specific agency
class AgencyDetailScreen extends ConsumerWidget {
  const AgencyDetailScreen({
    required this.agency,
    super.key,
  });

  final Agency agency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final stats = ref.watch(agencyStatsProvider(agency));

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: stats.when(
              data: (agencyStats) => ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  // Agency Header Card
                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            appColors.purpleGradientStart,
                            appColors.purpleGradientEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            agency.icon,
                            size: 64,
                            color: appColors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            agency.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: appColors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            agency.description.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: appColors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grand Totals Card
                  _buildStatCard(
                    context,
                    appColors,
                    'OVERVIEW',
                    Icons.dashboard,
                    [
                      _buildStatRow('Total Bookings', agencyStats.totalBookings.toString(), appColors),
                      _buildStatRow('Total Charges', agencyStats.totalCharges.toString(), appColors),
                      _buildStatRow('Unique Persons', agencyStats.uniquePersons.toString(), appColors),
                      _buildStatRow('Avg Charges/Booking', agencyStats.averageChargesPerBooking.toStringAsFixed(1), appColors),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // By Year Card
                  if (agencyStats.bookingsByYear.isNotEmpty)
                    _buildStatCard(
                      context,
                      appColors,
                      'BOOKINGS BY YEAR',
                      Icons.calendar_today,
                      agencyStats.yearsSorted
                          .map((entry) => _buildStatRow(
                                entry.key.toString(),
                                entry.value.toString(),
                                appColors,
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 12),

                  // By Gender Card (with percentages)
                  if (agencyStats.bookingsByGender.isNotEmpty)
                    _buildStatCardWithPercentages(
                      context,
                      appColors,
                      'BOOKINGS BY GENDER',
                      Icons.people,
                      agencyStats.getTopItems(agencyStats.bookingsByGender, 10),
                      agencyStats.totalBookings,
                    ),
                  const SizedBox(height: 12),

                  // By Race Card (with percentages)
                  if (agencyStats.bookingsByRace.isNotEmpty)
                    _buildStatCardWithPercentages(
                      context,
                      appColors,
                      'BOOKINGS BY RACE',
                      Icons.diversity_3,
                      agencyStats.getTopItems(agencyStats.bookingsByRace, 10),
                      agencyStats.totalBookings,
                    ),
                  const SizedBox(height: 12),

                  // By Charge Level & Degree Card (hierarchical)
                  if (agencyStats.chargesByLevelAndDegree.isNotEmpty)
                    _buildChargesHierarchyCard(
                      context,
                      appColors,
                      agencyStats.chargesByLevelSorted,
                    ),
                ],
              ),
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
                        color: context.appColors.accentPink,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ERROR LOADING STATS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.appColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textLight,
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

  Widget _buildStatCard(
    BuildContext context,
    dynamic appColors,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appColors.lightPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: appColors.primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: appColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, dynamic appColors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: appColors.textMedium,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: appColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }

  /// Build stat card with percentages (3 columns)
  Widget _buildStatCardWithPercentages(
    BuildContext context,
    dynamic appColors,
    String title,
    IconData icon,
    List<MapEntry<String, int>> items,
    int total,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appColors.lightPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: appColors.primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: appColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((entry) {
              final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    // Label (1/3 of available space)
                    Expanded(
                      flex: 1,
                      child: Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: appColors.textMedium,
                        ),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Value (1/3 of available space)
                    Expanded(
                      flex: 1,
                      child: Text(
                        entry.value.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: appColors.primaryPurple,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Percentage (1/3 of available space)
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${percentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: appColors.accentPink,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build hierarchical charges card with level -> degree structure
  Widget _buildChargesHierarchyCard(
    BuildContext context,
    dynamic appColors,
    List<dynamic> chargesByLevel, // List<ChargesByLevelAndDegree>
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appColors.lightPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.gavel,
                    color: appColors.primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'LEVEL & DEGREE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: appColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Display each level with its degrees
            ...chargesByLevel.asMap().entries.map((entry) {
              final index = entry.key;
              final levelData = entry.value;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (index > 0) const SizedBox(height: 12),
                  if (index > 0) Divider(color: appColors.border, height: 1),
                  if (index > 0) const SizedBox(height: 12),
                  
                  // Level header (e.g., FELONY: 400)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        levelData.level.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: appColors.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: appColors.primaryPurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          levelData.totalCount.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: appColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Degrees under this level (indented, with percentages)
                  ...levelData.degreesSorted.map((degreeEntry) {
                    final percentage = levelData.totalCount > 0 
                        ? (degreeEntry.value / levelData.totalCount * 100) 
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(left: 20, top: 4),
                      child: Row(
                        children: <Widget>[
                          // Degree label (1/3 of available space)
                          Expanded(
                            flex: 1,
                            child: Text(
                              degreeEntry.key.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: appColors.textMedium,
                              ),
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Value (1/3 of available space) - PURPLE to match other cards
                          Expanded(
                            flex: 1,
                            child: Text(
                              degreeEntry.value.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: appColors.primaryPurple,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Percentage (1/3 of available space) - PINK to match other cards
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${percentage.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: appColors.accentPink,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

