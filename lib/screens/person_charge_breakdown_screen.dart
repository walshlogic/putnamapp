import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../providers/booking_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

/// Screen showing charge breakdown for a person
class PersonChargeBreakdownScreen extends ConsumerWidget {
  const PersonChargeBreakdownScreen({
    required this.personName,
    super.key,
  });

  final String personName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final bookingsAsync = ref.watch(bookingsByNameProvider(personName));

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
                      Icons.person,
                      color: appColors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              context.push(
                                RoutePaths.personBookings,
                                extra: personName,
                              );
                            },
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    personName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: appColors.white,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: appColors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CHARGE BREAKDOWN',
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

          // Content
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'NO BOOKINGS FOUND',
                        style: TextStyle(
                          fontSize: 16,
                          color: appColors.textLight,
                        ),
                      ),
                    ),
                  );
                }

                // Group charges by charge name
                final Map<String, int> chargeCounts = <String, int>{};
                for (final booking in bookings) {
                  for (final charge in booking.chargeDetails) {
                    final chargeName = charge.charge.toUpperCase().trim();
                    if (chargeName.isNotEmpty) {
                      chargeCounts[chargeName] =
                          (chargeCounts[chargeName] ?? 0) + 1;
                    }
                  }
                }

                // Sort by count (descending), then by name
                final sortedCharges = chargeCounts.entries.toList()
                  ..sort((a, b) {
                    final countCompare = b.value.compareTo(a.value);
                    if (countCompare != 0) return countCompare;
                    return a.key.compareTo(b.key);
                  });

                if (sortedCharges.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'NO CHARGES FOUND',
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
                  itemCount: sortedCharges.length,
                  itemBuilder: (context, index) {
                    final entry = sortedCharges[index];
                    final chargeName = entry.key;
                    final count = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            // Count Badge
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: appColors.primaryPurple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  count.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: appColors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Charge Name
                            Expanded(
                              child: Text(
                                chargeName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: appColors.textDark,
                                ),
                              ),
                            ),
                          ],
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

