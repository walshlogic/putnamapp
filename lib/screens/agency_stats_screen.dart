import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/agency.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

/// Agency Statistics screen
class AgencyStatsScreen extends ConsumerWidget {
  const AgencyStatsScreen({super.key});

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
              children: Agency.all.map((agency) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAgencyButton(
                    context,
                    appColors,
                    agency,
                  ),
                );
              }).toList(),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildAgencyButton(
    BuildContext context,
    dynamic appColors,
    Agency agency,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(RoutePaths.agencyDetail, extra: agency);
        },
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
                    agency.icon,
                    color: appColors.primaryPurple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    agency.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: appColors.textDark,
                    ),
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

