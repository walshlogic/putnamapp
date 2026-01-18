import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import 'booking_providers.dart';
import 'storage_providers.dart';

/// Storage key for last viewed jail log
const String _lastViewedJailLogKey = 'last_viewed_jail_log';

/// Provider to get last viewed jail log timestamp
final lastViewedJailLogProvider = FutureProvider<DateTime?>((ref) async {
  final storageAsync = ref.watch(storageServiceProvider);
  return storageAsync.when(
    data: (storage) => storage.getDateTime(_lastViewedJailLogKey),
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider to mark jail log as viewed
final markJailLogAsViewedProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final storageAsync = await ref.read(storageServiceProvider.future);
    await storageAsync.setDateTime(_lastViewedJailLogKey, DateTime.now());
    ref.invalidate(lastViewedJailLogProvider);
  };
});

/// Provider to check if there are new bookings
final hasNewBookingsProvider = FutureProvider<bool>((ref) async {
  final lastViewedAsync = await ref.watch(lastViewedJailLogProvider.future);

  // If never viewed, show star
  if (lastViewedAsync == null) return true;

  // Get the most recent booking date from the bookings provider
  final bookingsAsync = ref.watch(recentBookingsProvider);

  return bookingsAsync.when(
    data: (List<JailBooking> bookings) {
      if (bookings.isEmpty) return false;

      // Get the most recent booking date
      final mostRecentDate = bookings.first.bookingDate;

      // Show star if most recent booking is after last viewed
      return mostRecentDate.isAfter(lastViewedAsync);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

