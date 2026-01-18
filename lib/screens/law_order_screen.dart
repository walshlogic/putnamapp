import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

/// Law & Order screen
class LawOrderScreen extends ConsumerWidget {
  const LawOrderScreen({super.key});

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
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        appColors.primaryPurple,
                        appColors.darkPurple,
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
                            Icons.gavel,
                            color: appColors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'LAW & ORDER',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: appColors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Public Safety Information',
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2x2 Grid of Features
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: <Widget>[
                    // Jail Log
                    _buildFeatureCard(
                      context,
                      appColors,
                      icon: Icons.local_police,
                      title: 'JAIL\nLOG',
                      gradientStart: appColors.primaryPurple,
                      gradientEnd: appColors.darkPurple,
                      onTap: () => context.push(RoutePaths.bookings),
                    ),

                    // Top 100 Lists
                    _buildFeatureCard(
                      context,
                      appColors,
                      icon: Icons.emoji_events,
                      title: 'TOP 100\nLISTS',
                      gradientStart: appColors.accentPink,
                      gradientEnd: appColors.accentPinkDark,
                      onTap: () => context.push(RoutePaths.topTen),
                    ),

                    // Sex Offender Registry
                    _buildFeatureCard(
                      context,
                      appColors,
                      icon: Icons.warning_amber_rounded,
                      title: 'OFFENDER\nREGISTRY',
                      gradientStart: appColors.accentOrange,
                      gradientEnd: appColors.accentOrangeDark,
                      onTap: () => context.push(RoutePaths.sexOffenders),
                    ),

                    // Agency Stats
                    _buildFeatureCard(
                      context,
                      appColors,
                      icon: Icons.analytics,
                      title: 'AGENCY\nSTATS',
                      gradientStart: appColors.accentTeal,
                      gradientEnd: appColors.accentTealDark,
                      onTap: () => context.push(RoutePaths.agencyStats),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    dynamic appColors, {
    required IconData icon,
    required String title,
    required Color gradientStart,
    required Color gradientEnd,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  gradientStart,
                  gradientEnd,
                ],
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
                final minDimension = buttonWidth < buttonHeight ? buttonWidth : buttonHeight;
                
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
                    Icon(
                      icon,
                      size: iconSize,
                      color: appColors.white,
                    ),
                    SizedBox(height: gap),
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: appColors.white,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
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
}
