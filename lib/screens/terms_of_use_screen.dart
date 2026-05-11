import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/settings_drawer.dart';

class TermsOfUseScreen extends ConsumerWidget {
  const TermsOfUseScreen({super.key});

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
                      child: Icon(Icons.description_outlined,
                          color: appColors.primaryPurple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ABOUT THIS APP',
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
                      "There's no formal \"terms of use\" here because this isn't a "
                      "real product — it's my personal coding project, built to learn "
                      "Flutter, Supabase, and a pile of other tools. It's only on a "
                      "few phones (mine and a small group of testers I know), and "
                      "there's no plan to release it to the public in this or any "
                      "other form.\n\n"
                      "A few honest notes:\n\n"
                      "• The data — jail logs, court records, agency stats, the "
                      "offender registry, incidents — comes from public Putnam County, "
                      "Florida sources. It can be wrong, incomplete, stale, or "
                      "mismatched to the wrong person. Don't rely on it for anything "
                      "real. If you need accurate information, go to the original "
                      "source (the Sheriff's Office, the Clerk of Court, etc.).\n\n"
                      "• An arrest or booking record is not a conviction. People shown "
                      "in this app may never be charged, or may be found not guilty.\n\n"
                      "• Features come and go without warning while I experiment. Stuff "
                      "may break.\n\n"
                      "• If you have feedback, want your account removed, or think "
                      "something's wrong, just tell me directly.\n\n"
                      "Thanks for helping me test it.",
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
