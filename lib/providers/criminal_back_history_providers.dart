import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/criminal_back_history.dart';
import '../models/criminal_back_history_filters.dart';
import '../repositories/criminal_back_history_repository.dart';
import '../services/supabase_service.dart';

/// Provider for CriminalBackHistoryRepository
final criminalBackHistoryRepositoryProvider =
    Provider<CriminalBackHistoryRepository>((ref) {
  return SupabaseCriminalBackHistoryRepository(SupabaseService.client);
});

/// Provider for criminal back history cases with filters
final criminalBackHistoryProvider =
    FutureProvider.family<CriminalBackHistoryResults, CriminalBackHistoryFilters>((
  ref,
  filters,
) async {
  final repository = ref.watch(criminalBackHistoryRepositoryProvider);
  return repository.getCases(filters);
});

/// Provider for recent criminal cases (last 30 days)
final recentCriminalBackHistoryProvider = FutureProvider<List<CriminalBackHistory>>((
  ref,
) async {
  final repository = ref.watch(criminalBackHistoryRepositoryProvider);
  final filters = CriminalBackHistoryFilters.recent();
  final results = await repository.getCases(filters);
  return results.cases;
});

/// Provider for a single case by case number
final criminalBackHistoryByCaseNumberProvider =
    FutureProvider.family<CriminalBackHistory?, String>((ref, caseNumber) async {
  final repository = ref.watch(criminalBackHistoryRepositoryProvider);
  return repository.getCaseByCaseNumber(caseNumber);
});

/// Provider for cases by name
final criminalBackHistoryByNameProvider =
    FutureProvider.family<List<CriminalBackHistory>, String>((ref, name) async {
  final repository = ref.watch(criminalBackHistoryRepositoryProvider);
  return repository.getCasesByName(name);
});

/// Provider for cases by person (name + date of birth)
final criminalBackHistoryByPersonProvider = FutureProvider.family<
    List<CriminalBackHistory>,
    ({String lastName, String firstName, DateTime dateOfBirth})>((ref, person) async {
  final repository = ref.watch(criminalBackHistoryRepositoryProvider);
  return repository.getCasesByPerson(
    person.lastName,
    person.firstName,
    person.dateOfBirth,
  );
});

