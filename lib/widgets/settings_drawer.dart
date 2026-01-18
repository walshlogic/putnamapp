import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_names.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';

class SettingsDrawer extends ConsumerWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final isPremium = ref.watch(isPremiumUserProvider);
    
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // User info at top
                  userProfileAsync.when(
                    data: (profile) => Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: appColors.white,
                          child: Icon(
                            Icons.person,
                            color: appColors.primaryPurple,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      profile?.displayName ?? 'User',
                                      style: TextStyle(
                                        color: appColors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isPremium) ...<Widget>[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                profile?.email ?? '',
                                style: TextStyle(
                                  color: appColors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    loading: () => SizedBox(
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              appColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    error: (_, __) => Icon(
                      Icons.error_outline,
                      color: appColors.white,
                    ),
                  ),
                  // Settings title at bottom
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'SETTINGS',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: appColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'PREFERENCES & OPTIONS',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: appColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildSettingItem(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'PRIVACY',
              subtitle: 'Privacy policy',
              onTap: () {
                Navigator.pop(context); // Close drawer
                context.pushNamed(RouteNames.privacy);
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.data_usage_outlined,
              title: 'DATA USAGE',
              subtitle: 'How data is used',
              onTap: () {
                Navigator.pop(context); // Close drawer
                context.pushNamed(RouteNames.dataUsage);
              },
            ),
            _buildAccountItem(
              context,
              ref,
              icon: Icons.person_outline,
              title: 'PROFILE',
              subtitle: 'View & edit profile',
              onTap: () {
                Navigator.pop(context); // Close drawer
                context.pushNamed(RouteNames.profile);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    
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
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: appColors.textLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: appColors.divider,
      ),
      onTap: onTap ?? () {
        // TODO: Navigate to setting detail screens
      },
    );
  }

  Widget _buildAccountItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final effectiveColor = textColor ?? appColors.textDark;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: textColor?.withValues(alpha: 0.1) ?? appColors.lightPurple,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon, 
          color: textColor ?? appColors.primaryPurple, 
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: effectiveColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: textColor?.withValues(alpha: 0.7) ?? appColors.textLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: textColor ?? appColors.divider,
      ),
      onTap: onTap,
    );
  }
}

