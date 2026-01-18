import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booked_person.dart';
import '../repositories/person_repository.dart';
import '../services/supabase_service.dart';

/// Provider for PersonRepository
final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return SupabasePersonRepository(SupabaseService.client);
});

/// Provider for person data by name
final personByNameProvider = FutureProvider.family<BookedPerson?, String>(
  (ref, name) async {
    final repository = ref.watch(personRepositoryProvider);
    return repository.getPersonByName(name);
  },
);

/// Provider for frequent offenders
final frequentOffendersProvider = FutureProvider<List<BookedPerson>>((ref) async {
  final repository = ref.watch(personRepositoryProvider);
  return repository.getFrequentOffenders(limit: 20);
});

