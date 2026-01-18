import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/booked_person.dart';

/// Abstract repository for booked person data operations
abstract class PersonRepository {
  /// Get person data by name
  Future<BookedPerson?> getPersonByName(String name);

  /// Get top frequent offenders
  Future<List<BookedPerson>> getFrequentOffenders({int limit = 20});

  /// Get persons by birth year range
  Future<List<BookedPerson>> getPersonsByBirthYear({
    required int minYear,
    required int maxYear,
  });
}

/// Supabase implementation of PersonRepository
class SupabasePersonRepository implements PersonRepository {
  SupabasePersonRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<BookedPerson?> getPersonByName(String name) async {
    try {
      final response = await _client
          .from('booked_persons')
          .select('*')
          .eq('name', name)
          .maybeSingle();

      if (response == null) return null;

      return BookedPerson.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch person data', e);
      }
      throw DatabaseException('Failed to load person: $e');
    }
  }

  @override
  Future<List<BookedPerson>> getFrequentOffenders({int limit = 20}) async {
    try {
      final response = await _client
          .from('booked_persons')
          .select('*')
          .order('total_bookings', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map((json) => BookedPerson.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch frequent offenders', e);
      }
      throw DatabaseException('Failed to load frequent offenders: $e');
    }
  }

  @override
  Future<List<BookedPerson>> getPersonsByBirthYear({
    required int minYear,
    required int maxYear,
  }) async {
    try {
      final response = await _client
          .from('booked_persons')
          .select('*')
          .gte('birth_year_low', minYear)
          .lte('birth_year_high', maxYear)
          .order('total_bookings', ascending: false);

      return (response as List<dynamic>)
          .map((json) => BookedPerson.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch persons by birth year', e);
      }
      throw DatabaseException('Failed to load persons: $e');
    }
  }
}

