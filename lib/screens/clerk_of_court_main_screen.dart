import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

/// Clerk of Court main screen with navigation buttons
class ClerkOfCourtMainScreen extends StatelessWidget {
  const ClerkOfCourtMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final padding = context.responsivePadding;
    final spacing = context.responsiveSpacing;
    final crossAxisCount = context.gridCrossAxisCount;

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
                    padding: EdgeInsets.all(spacing * 0.83), // ~20px on mobile, ~24px on tablet
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
                              Icons.description,
                              color: appColors.white,
                              size: context.isTablet ? 40 : 32,
                            ),
                            SizedBox(width: spacing * 0.75),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'CLERK OF COURT',
                                    style: TextStyle(
                                      fontSize: context.isTablet ? 24 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: appColors.white,
                                    ),
                                  ),
                                  SizedBox(height: spacing * 0.25),
                                  Text(
                                    'Court Records & Documents',
                                    style: TextStyle(
                                      fontSize: context.isTablet ? 15 : 13,
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
                  SizedBox(height: spacing * 1.5),

                  // Feature Cards Grid
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: spacing * 0.75,
                    crossAxisSpacing: spacing * 0.75,
                    childAspectRatio: ResponsiveUtils.getCardAspectRatio(context),
                    children: <Widget>[
                      // Traffic Citations
                      _buildFeatureCard(
                        context,
                        appColors,
                        icon: Icons.traffic,
                        title: 'TRAFFIC\nCITATIONS',
                        gradientStart: appColors.primaryPurple,
                        gradientEnd: appColors.darkPurple,
                        onTap: () {
                          context.push(RoutePaths.trafficCitations);
                        },
                      ),
                      // Criminal Back History
                      _buildFeatureCard(
                        context,
                        appColors,
                        icon: Icons.gavel,
                        title: 'CRIMINAL\nHISTORY',
                        gradientStart: appColors.accentOrange,
                        gradientEnd: appColors.accentOrangeDark,
                        onTap: () {
                          context.push(RoutePaths.criminalBackHistory);
                        },
                      ),
                    ],
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

  Widget _buildFeatureCard(
    BuildContext context,
    dynamic appColors, {
    required IconData icon,
    required String title,
    required Color gradientStart,
    required Color gradientEnd,
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    final iconSize = context.isTablet ? 64.0 : 48.0;
    final fontSize = context.isTablet ? 20.0 : 16.0;
    final spacing = context.responsiveSpacing;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDisabled
                ? null
                : <BoxShadow>[
                    BoxShadow(
                      color: gradientStart.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    icon,
                    size: iconSize,
                    color: appColors.white,
                  ),
                  SizedBox(height: spacing * 0.75),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: appColors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


