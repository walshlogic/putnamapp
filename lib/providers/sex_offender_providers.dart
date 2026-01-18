import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sex_offender.dart';
import '../models/sex_offender_filters.dart';
import '../repositories/sex_offender_repository.dart';
import '../services/supabase_service.dart';

/// Provider for SexOffenderRepository
final sexOffenderRepositoryProvider = Provider<SexOffenderRepository>((ref) {
  return SupabaseSexOffenderRepository(SupabaseService.client);
});

/// Provider for Putnam County sex offenders (legacy, uses default filters)
final putnamOffendersProvider = FutureProvider<List<SexOffender>>((ref) async {
  final repository = ref.watch(sexOffenderRepositoryProvider);
  return repository.getPutnamOffenders();
});

/// Provider for filtered sex offenders
final filteredOffendersProvider =
    FutureProvider.family<List<SexOffender>, SexOffenderFilters>((ref, filters) async {
  final repository = ref.watch(sexOffenderRepositoryProvider);
  return repository.getFilteredOffenders(filters);
});

