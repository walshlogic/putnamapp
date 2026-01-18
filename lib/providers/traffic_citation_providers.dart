import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/traffic_citation.dart';
import '../models/traffic_citation_filters.dart';
import '../repositories/traffic_citation_repository.dart';
import '../services/supabase_service.dart';

/// Provider for TrafficCitationRepository
final trafficCitationRepositoryProvider =
    Provider<TrafficCitationRepository>((ref) {
  return SupabaseTrafficCitationRepository(SupabaseService.client);
});

/// Provider for traffic citations with filters
final trafficCitationsProvider =
    FutureProvider.family<TrafficCitationResults, TrafficCitationFilters>((
  ref,
  filters,
) async {
  final repository = ref.watch(trafficCitationRepositoryProvider);
  return repository.getCitations(filters);
});

/// Provider for recent traffic citations (last 30 days)
final recentTrafficCitationsProvider = FutureProvider<List<TrafficCitation>>((
  ref,
) async {
  final repository = ref.watch(trafficCitationRepositoryProvider);
  final filters = TrafficCitationFilters.recent();
  final results = await repository.getCitations(filters);
  return results.citations;
});

/// Provider for a single citation by case number
final trafficCitationByCaseNumberProvider =
    FutureProvider.family<TrafficCitation?, String>((ref, caseNumber) async {
  final repository = ref.watch(trafficCitationRepositoryProvider);
  return repository.getCitationByCaseNumber(caseNumber);
});

/// Provider for citations by name
final trafficCitationsByNameProvider =
    FutureProvider.family<List<TrafficCitation>, String>((ref, name) async {
  final repository = ref.watch(trafficCitationRepositoryProvider);
  return repository.getCitationsByName(name);
});

/// Provider for citations by person (name + date of birth)
final trafficCitationsByPersonProvider = FutureProvider.family<
    List<TrafficCitation>,
    ({String lastName, String firstName, DateTime dateOfBirth})>((ref, person) async {
  final repository = ref.watch(trafficCitationRepositoryProvider);
  return repository.getCitationsByPerson(
    person.lastName,
    person.firstName,
    person.dateOfBirth,
  );
});

