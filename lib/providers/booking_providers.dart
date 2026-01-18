import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/booking.dart';
import '../models/booking_filters.dart';
import '../repositories/booking_repository.dart';
import '../services/supabase_service.dart';

/// Provider for BookingRepository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return SupabaseBookingRepository(SupabaseService.client);
});

/// Provider for filtered bookings with pagination
final filteredBookingsProvider = FutureProvider.family<
    BookingResults,
    BookingFilters
>((ref, filters) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookings(filters);
});

/// Provider for bookings by name
final bookingsByNameProvider = FutureProvider.family<
    List<JailBooking>,
    String
>((ref, name) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByName(name);
});

/// Provider for bookings by MNI number
final bookingsByMniProvider = FutureProvider.family<
    List<JailBooking>,
    String
>((ref, mniNo) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByMni(mniNo);
});

/// Provider for people charged with a specific charge
final peopleByChargeProvider = FutureProvider.family<
    List<PersonWithCharge>,
    PeopleByChargeParams
>((ref, params) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getPeopleByCharge(params.chargeName, params.timeRange);
});

/// Parameters for people by charge provider
class PeopleByChargeParams {
  const PeopleByChargeParams({
    required this.chargeName,
    required this.timeRange,
  });

  final String chargeName;
  final String timeRange;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeopleByChargeParams &&
          runtimeType == other.runtimeType &&
          chargeName == other.chargeName &&
          timeRange == other.timeRange;

  @override
  int get hashCode => chargeName.hashCode ^ timeRange.hashCode;
}

/// Provider for bookings by date
final bookingsByDateProvider = FutureProvider.family<
    List<JailBooking>,
    DateTime
>((ref, date) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByDate(date);
});

/// Legacy provider for backwards compatibility (uses 24HRS default)
final recentBookingsProvider = FutureProvider<List<JailBooking>>((ref) async {
  final results = await ref.watch(
    filteredBookingsProvider(
      const BookingFilters(timeRange: AppConfig.timeRange24Hours),
    ).future,
  );
  return results.bookings;
});

