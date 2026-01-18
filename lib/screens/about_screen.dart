import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/route_paths.dart';
import '../theme/app_theme.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/settings_drawer.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = Theme.of(context).extension<AppColors>()!;

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
                // App Logo/Icon
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          appColors.purpleGradientStart,
                          appColors.purpleGradientEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: appColors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_city,
                      size: 60,
                      color: appColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // App Name
                Text(
                  'PUTNAM.APP',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: appColors.primaryPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'BE CONNECTED. STAY INFORMED',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: appColors.textMedium),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // About Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                                Icons.info_outline,
                                color: appColors.primaryPurple,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ABOUT',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Putnam.app provides easy access to important local information for Putnam County, Florida residents and visitors.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'FEATURES INCLUDE:',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: appColors.primaryPurple,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          context,
                          appColors,
                          'Real-time weather updates',
                        ),
                        _buildFeatureItem(context, appColors, 'Jail log'),
                        _buildFeatureItem(
                          context,
                          appColors,
                          'Registered sex offenders registry',
                        ),
                        _buildFeatureItem(context, appColors, 'Top 100 lists'),
                        const SizedBox(height: 16),
                        Text(
                          'RESOURCES',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: appColors.primaryPurple,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: <Widget>[
                              TextButton.icon(
                                onPressed: () =>
                                    context.push(RoutePaths.dataUsage),
                                icon: Icon(
                                  Icons.data_usage_outlined,
                                  color: appColors.primaryPurple,
                                ),
                                label: Text(
                                  'Data Usage',
                                  style: TextStyle(
                                    color: appColors.primaryPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    context.push(RoutePaths.privacy),
                                icon: Icon(
                                  Icons.privacy_tip_outlined,
                                  color: appColors.primaryPurple,
                                ),
                                label: Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color: appColors.primaryPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Version Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'VERSION',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '0.8.2',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: appColors.primaryPurple),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    AppColors appColors,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: appColors.primaryPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
