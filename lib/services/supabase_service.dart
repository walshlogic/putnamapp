import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static late final SupabaseClient _client;

  static void configure(SupabaseClient client) {
    _client = client;
  }

  static SupabaseClient get client => _client;
}

