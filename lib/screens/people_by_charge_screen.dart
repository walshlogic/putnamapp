import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../providers/booking_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

/// Screen showing people charged with a specific charge
class PeopleByChargeScreen extends ConsumerWidget {
  const PeopleByChargeScreen({
    required this.chargeName,
    required this.timeRange,
    super.key,
  });

  final String chargeName;
  final String timeRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final peopleAsync = ref.watch(
      peopleByChargeProvider(
        PeopleByChargeParams(
          chargeName: chargeName,
          timeRange: timeRange,
        ),
      ),
    );

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  appColors.accentPink,
                  appColors.accentPinkDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                            chargeName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: appColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PEOPLE CHARGED',
                            style: TextStyle(
                              fontSize: 12,
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

          // List Content
          Expanded(
            child: peopleAsync.when(
              data: (people) {
                if (people.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'NO PEOPLE FOUND',
                        style: TextStyle(
                          fontSize: 16,
                          color: appColors.textLight,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    final dateFormat = DateFormat('MM/dd/yy');
                    final dateString = dateFormat.format(person.bookingDate);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          context.push(
                            RoutePaths.personBookings,
                            extra: person.name,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              // Count Badge (only show if count > 1)
                              if (person.count > 1)
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: appColors.primaryPurple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      person.count.toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: appColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              if (person.count > 1) const SizedBox(width: 16),

                              // Name and Date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      person.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: appColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateString,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: appColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Chevron
                              Icon(
                                Icons.chevron_right,
                                color: appColors.textLight,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: appColors.accentPink,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ERROR LOADING DATA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: appColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}

