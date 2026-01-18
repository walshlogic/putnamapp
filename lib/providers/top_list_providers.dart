import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/top_list_item.dart';
import '../repositories/top_list_repository.dart';

/// Provider for TopListRepository
final topListRepositoryProvider = Provider<TopListRepository>((ref) {
  return SupabaseTopListRepository();
});

/// Provider for Top 100 Arrested Persons with time range filter
final topArrestedPersonsProvider = FutureProvider.family<List<TopListItem>, String>((ref, timeRange) async {
  final repository = ref.watch(topListRepositoryProvider);
  return repository.getTopArrestedPersons(timeRange: timeRange);
});

/// Provider for Top 100 Felony Charges with time range filter
final topFelonyChargesProvider = FutureProvider.family<List<TopListItem>, String>((ref, timeRange) async {
  final repository = ref.watch(topListRepositoryProvider);
  return repository.getTopFelonyCharges(timeRange: timeRange);
});

/// Provider for Top 100 Misdemeanor Charges with time range filter
final topMisdemeanorChargesProvider = FutureProvider.family<List<TopListItem>, String>((ref, timeRange) async {
  final repository = ref.watch(topListRepositoryProvider);
  return repository.getTopMisdemeanorCharges(timeRange: timeRange);
});

/// Provider for Top 100 All Charges with time range filter
final topAllChargesProvider = FutureProvider.family<List<TopListItem>, String>((ref, timeRange) async {
  final repository = ref.watch(topListRepositoryProvider);
  return repository.getTopAllCharges(timeRange: timeRange);
});

/// Provider for Top 100 Booking Days with time range filter
final topBookingDaysProvider = FutureProvider.family<List<TopListItem>, String>((ref, timeRange) async {
  final repository = ref.watch(topListRepositoryProvider);
  return repository.getTopBookingDays(timeRange: timeRange);
});

