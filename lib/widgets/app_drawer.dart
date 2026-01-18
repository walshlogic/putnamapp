import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Drawer(
      child: Container(
        color: appColors.scaffoldBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Icon(Icons.location_city, size: 48, color: appColors.white),
                  const SizedBox(height: 12),
                  Text(
                    AppConfig.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: appColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppConfig.appSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: appColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.home,
              title: 'HOME',
              onTap: () {
                Navigator.pop(context);
                context.go(RoutePaths.home);
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.wb_sunny,
              title: 'WEATHER',
              onTap: () {
                Navigator.pop(context);
                context.push(RoutePaths.weather);
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.local_police,
              title: 'JAIL LOG',
              onTap: () {
                Navigator.pop(context);
                context.push(RoutePaths.bookings);
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.personal_injury_outlined,
              title: 'SEX OFFENDER REGISTRY',
              onTap: () {
                Navigator.pop(context);
                context.push(RoutePaths.sexOffenders);
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.gavel,
              title: 'LAW & ORDER',
              onTap: () {
                Navigator.pop(context);
                context.push(RoutePaths.lawOrder);
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.description,
              title: 'CLERK OF COURT',
              onTap: () {
                Navigator.pop(context);
                context.push(RoutePaths.clerkOfCourt);
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.article,
              title: 'NEWS',
              onTap: () {
                Navigator.pop(context);
                context.push(RoutePaths.news);
              },
            ),
            const Divider(height: 32),
            _buildDrawerItem(
              context,
              icon: Icons.info_outline,
              title: 'ABOUT',
              onTap: () {
                Navigator.pop(context);
                context.push(RoutePaths.about);
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.contact_mail,
              title: 'CONTACT',
              onTap: () {
                Navigator.pop(context);
                context.push(RoutePaths.contact);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final appColors = context.appColors;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: appColors.lightPurple,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: appColors.primaryPurple, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: appColors.textDark,
        ),
      ),
      onTap: onTap,
    );
  }
}
