import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agency.dart';
import '../models/agency_stats.dart';
import '../repositories/agency_stats_repository.dart';
import '../services/supabase_service.dart';

/// Provider for AgencyStatsRepository
final agencyStatsRepositoryProvider = Provider<AgencyStatsRepository>((ref) {
  return SupabaseAgencyStatsRepository(SupabaseService.client);
});

/// Provider for agency statistics by agency ID
final agencyStatsProvider = FutureProvider.family<AgencyStats, Agency>(
  (ref, agency) async {
    final repository = ref.watch(agencyStatsRepositoryProvider);
    return repository.getAgencyStats(agency.id, agency.name);
  },
);

