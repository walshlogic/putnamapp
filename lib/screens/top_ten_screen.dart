import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/top_list_item.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

/// Top 100 Lists screen
class TopTenScreen extends ConsumerWidget {
  const TopTenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _buildTopTenButton(
                  context,
                  appColors,
                  title: 'TOP 100 ARRESTED PERSONS',
                  subtitle: 'Most frequently booked individuals',
                  icon: Icons.person,
                  onTap: () {
                    context.push(
                      RoutePaths.topListDetail,
                      extra: TopListCategory.arrestedPersons,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildTopTenButton(
                  context,
                  appColors,
                  title: 'TOP 100 FELONY CHARGES',
                  subtitle: 'Most common felony charges',
                  icon: Icons.gavel,
                  onTap: () {
                    context.push(
                      RoutePaths.topListDetail,
                      extra: TopListCategory.felonyCharges,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildTopTenButton(
                  context,
                  appColors,
                  title: 'TOP 100 MISDEMEANOR CHARGES',
                  subtitle: 'Most common misdemeanor charges',
                  icon: Icons.policy,
                  onTap: () {
                    context.push(
                      RoutePaths.topListDetail,
                      extra: TopListCategory.misdemeanorCharges,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildTopTenButton(
                  context,
                  appColors,
                  title: 'TOP 100 ALL CHARGES',
                  subtitle: 'Most common charges overall',
                  icon: Icons.format_list_numbered,
                  onTap: () {
                    context.push(
                      RoutePaths.topListDetail,
                      extra: TopListCategory.allCharges,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildTopTenButton(
                  context,
                  appColors,
                  title: 'TOP 100 BOOKING DAYS',
                  subtitle: 'Days with the most bookings',
                  icon: Icons.calendar_today,
                  onTap: () {
                    context.push(
                      RoutePaths.topListDetail,
                      extra: TopListCategory.bookingDays,
                    );
                  },
                ),
              ],
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildTopTenButton(
    BuildContext context,
    dynamic appColors, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  appColors.purpleGradientStart.withValues(alpha: 0.1),
                  appColors.purpleGradientEnd.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appColors.lightPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: appColors.primaryPurple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: appColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
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
}

