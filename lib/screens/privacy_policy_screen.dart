import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/settings_drawer.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

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
                      child: Icon(Icons.privacy_tip_outlined,
                          color: appColors.primaryPurple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'PRIVACY',
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
                      "Quick version: this is a personal coding project, not a "
                      "commercial app. I'm using it to learn Flutter and Supabase.\n\n"
                      "You signed in so the app could remember you between sessions — "
                      "that's email + a display name, stored in Supabase. If you leave "
                      "comments or reviews, those are stored too. That's it. Nothing is "
                      "sold, shared with advertisers, or used for anything beyond making "
                      "the app work for the handful of people testing it.\n\n"
                      "Most of what the app displays (jail logs, court records, agency "
                      "stats, the offender registry, incidents) comes from public records "
                      "from Putnam County, Florida — I just aggregate it. I don't create "
                      "or control those underlying records, and they can be wrong, "
                      "incomplete, or out of date.\n\n"
                      "If you want your account or any data you added removed, just ask "
                      "me — I know everyone who has this installed.",
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
