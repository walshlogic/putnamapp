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
                      child: Icon(Icons.data_usage_outlined,
                          color: appColors.primaryPurple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'DATA USAGE',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Short answer: not much, and none of it goes anywhere.\n\n"
                      "This is a personal learning project. The only data tied to "
                      "you is your account (email + display name) and anything you "
                      "post in the app, like comments or reviews — all stored in "
                      "Supabase so the app works between sessions. No analytics SDKs, "
                      "no ad networks, no selling or sharing.\n\n"
                      "The bulk of what you see — jail logs, traffic citations, "
                      "criminal history, the offender registry, agency stats, "
                      "incidents — is public-record data pulled from Putnam County, "
                      "Florida sources. The app just collects and displays it; it "
                      "doesn't change those records and can't vouch for their "
                      "accuracy or completeness.\n\n"
                      "If you want anything tied to your account deleted, ask me — I "
                      "personally know everyone using this.",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.5),
                    ),
                  ),
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
}
