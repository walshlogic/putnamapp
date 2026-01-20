import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking_comment.dart';
import '../repositories/booking_comment_repository.dart';

/// Provider for BookingCommentRepository
final bookingCommentRepositoryProvider = Provider<BookingCommentRepository>((
  ref,
) {
  return SupabaseBookingCommentRepository(Supabase.instance.client);
});

/// Comments by MNI (most reliable)
final bookingCommentsByMniProvider =
    FutureProvider.family<List<BookingComment>, String>((ref, mniNo) async {
  final repository = ref.watch(bookingCommentRepositoryProvider);
  return repository.getCommentsByMni(mniNo);
});

/// Comments by name (fallback when no MNI)
final bookingCommentsByNameProvider =
    FutureProvider.family<List<BookingComment>, String>((ref, name) async {
  final repository = ref.watch(bookingCommentRepositoryProvider);
  return repository.getCommentsByName(name);
});
