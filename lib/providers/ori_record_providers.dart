import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/ori_record_repository.dart';
import '../services/supabase_service.dart';

final oriRecordRepositoryProvider = Provider<OriRecordRepository>((ref) {
  return SupabaseOriRecordRepository(SupabaseService.client);
});

final oriRecordSearchProvider = FutureProvider.autoDispose
    .family<OriRecordResults, OriRecordFilters>((ref, filters) async {
  final repo = ref.watch(oriRecordRepositoryProvider);
  return repo.search(filters);
});
