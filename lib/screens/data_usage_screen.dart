import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class DataUsageScreen extends ConsumerWidget {
  const DataUsageScreen({super.key});

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
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: appColors.lightPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.data_usage_outlined,
                        color: appColors.primaryPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'DATA USAGE',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  appColors,
                  'SUMMARY',
                  'Putnam.app uses data to provide app features, improve performance, '
                      'and support account-related services. We do not sell personal '
                      'information.',
                ),
                _buildSection(
                  context,
                  appColors,
                  'WHAT WE COLLECT',
                  '• Account data you provide when creating an account\n'
                      '• App usage events (features accessed, screens viewed)\n'
                      '• Device and connectivity metadata (for reliability and support)',
                ),
                _buildSection(
                  context,
                  appColors,
                  'HOW WE USE DATA',
                  '• Provide and secure account access\n'
                      '• Improve app stability and performance\n'
                      '• Personalize features based on subscription status',
                ),
                _buildSection(
                  context,
                  appColors,
                  'DATA SOURCES',
                  'The app displays public records from government sources in Putnam '
                      'County, Florida. We aggregate and present this data but do not '
                      'create or modify the underlying public records.',
                ),
                _buildSection(
                  context,
                  appColors,
                  'MORE DETAILS',
                  'See the Privacy Policy for full details about data collection, '
                      'usage, and your rights.',
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    AppColors appColors,
    String title,
    String content,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appColors.primaryPurple,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
