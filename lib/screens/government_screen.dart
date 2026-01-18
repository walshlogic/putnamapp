import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/route_paths.dart';
import '../theme/app_theme.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/settings_drawer.dart';
class GovernmentScreen extends ConsumerWidget {
  const GovernmentScreen({super.key});

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
                // Header
                Text(
                  'GOVERNMENT',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: appColors.primaryPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'SELECT A GOVERNMENT ENTITY',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: appColors.textMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Putnam County Button (Full Width)
                SizedBox(
                  width: double.infinity,
                  height: 140,
                  child: Card(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push(
                          RoutePaths.governmentDetail,
                          extra: 'Putnam County',
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
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
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.account_balance,
                                  size: 32,
                                  color: appColors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'PUTNAM COUNTY',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: appColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // City Buttons Row 1
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildCityButton(
                        context,
                        appColors,
                        'Palatka',
                        RoutePaths.governmentDetail,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCityButton(
                        context,
                        appColors,
                        'Crescent City',
                        RoutePaths.governmentDetail,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // City Buttons Row 2
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildCityButton(
                        context,
                        appColors,
                        'Interlachen',
                        RoutePaths.governmentDetail,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCityButton(
                        context,
                        appColors,
                        'Welaka',
                        RoutePaths.governmentDetail,
                      ),
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

  Widget _buildCityButton(
    BuildContext context,
    AppColors appColors,
    String cityName,
    String routePath,
  ) {
    return SizedBox(
      height: 140,
      child: Card(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(
              routePath,
              extra: cityName,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
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
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.location_city,
                      size: 28,
                      color: appColors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cityName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appColors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

