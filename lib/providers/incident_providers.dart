import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider is in legacy in Riverpod 3
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident.dart';
import '../repositories/incident_repository.dart';
import 'auth_providers.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  // Watch the session so the repo gets a fresh client when auth changes.
  ref.watch(currentSessionProvider);
  return IncidentRepository(Supabase.instance.client);
});

/// Filters applied to the incident list screen. Each non-null/non-empty
/// field narrows the query.
class IncidentFilters {
  IncidentFilters({
    this.search = '',
    this.category,
    this.from,
    this.to,
  });

  final String search;
  final String? category;
  final DateTime? from;
  final DateTime? to;

  IncidentFilters copyWith({
    String? search,
    Object? category = _sentinel,
    Object? from = _sentinel,
    Object? to = _sentinel,
  }) {
    return IncidentFilters(
      search: search ?? this.search,
      category: identical(category, _sentinel)
          ? this.category
          : category as String?,
      from: identical(from, _sentinel) ? this.from : from as DateTime?,
      to: identical(to, _sentinel) ? this.to : to as DateTime?,
    );
  }

  static const Object _sentinel = Object();

  @override
  bool operator ==(Object other) =>
      other is IncidentFilters &&
      search == other.search &&
      category == other.category &&
      from == other.from &&
      to == other.to;

  @override
  int get hashCode => Object.hash(search, category, from, to);
}

final incidentFiltersProvider =
    StateProvider<IncidentFilters>((ref) => IncidentFilters());

/// All incidents matching the current filters, newest first.
final incidentsProvider = FutureProvider<List<Incident>>((ref) async {
  final IncidentFilters f = ref.watch(incidentFiltersProvider);
  final IncidentRepository repo = ref.watch(incidentRepositoryProvider);
  return repo.listIncidents(
    search: f.search.isEmpty ? null : f.search,
    category: f.category,
    from: f.from,
    to: f.to,
  );
});

/// One incident with its attachments. Parameterized by id.
final incidentByIdProvider =
    FutureProvider.family<Incident, String>((ref, id) async {
  final IncidentRepository repo = ref.watch(incidentRepositoryProvider);
  return repo.getIncidentById(id);
});

/// Returns true if the current user is admin or elevated — drives the
/// "+ New Incident" button visibility and edit-screen access.
final canEditIncidentsProvider = FutureProvider<bool>((ref) async {
  // Re-evaluate whenever the session changes.
  ref.watch(currentSessionProvider);
  final IncidentRepository repo = ref.watch(incidentRepositoryProvider);
  return repo.currentUserCanEdit();
});
