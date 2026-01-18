import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../extensions/build_context_extensions.dart';
import '../../models/booking.dart';

/// Card widget to display booking count with "new items" indicator
class BookingCountCard extends ConsumerWidget {
  const BookingCountCard({
    required this.bookings,
    required this.hasNewBookings,
    super.key,
  });

  final AsyncValue<List<JailBooking>> bookings;
  final AsyncValue<bool> hasNewBookings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final cardTitleSize = context.cardTextStyles.cardTitleSize;

    return SizedBox(
      height: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: <Widget>[
            // Background gradient
            Positioned.fill(
              child: Container(
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
              ),
            ),

            // Center content
            Center(
              child: bookings.when(
                data: (List<JailBooking> data) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.local_police,
                        size: 32,
                        color: appColors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JAIL',
                        style: TextStyle(
                          fontSize: cardTitleSize * 0.75,
                          fontWeight: FontWeight.bold,
                          color: appColors.white,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'LOG',
                        style: TextStyle(
                          fontSize: cardTitleSize * 0.75,
                          fontWeight: FontWeight.bold,
                          color: appColors.white,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: appColors.white),
                ),
                error: (Object e, StackTrace st) => Center(
                  child: Icon(
                    Icons.error_outline,
                    color: appColors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Star badge (new items indicator)
            hasNewBookings.when(
              data: (bool showStar) {
                if (!showStar) return const SizedBox.shrink();
                return Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 42,
                    height: 38,
                    decoration: BoxDecoration(
                      color: appColors.accentPink,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.star,
                        color: appColors.white,
                        size: 22,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (Object e, StackTrace st) => const SizedBox.shrink(),
            ),

            // Count badge
            bookings.when(
              data: (List<JailBooking> data) {
                // Use the count directly since the repository already filtered for 24HRS
                // No need to re-filter here (causes timing issues)
                final int count24h = data.length;
                return Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 42,
                    height: 38,
                    decoration: BoxDecoration(
                      color: appColors.accentPink,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        count24h.toString(),
                        style: TextStyle(
                          color: appColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (Object e, StackTrace st) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
