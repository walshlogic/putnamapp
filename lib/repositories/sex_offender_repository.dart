import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../exceptions/app_exceptions.dart';
import '../models/sex_offender.dart';
import '../models/sex_offender_filters.dart';

/// Abstract repository for sex offender data operations
abstract class SexOffenderRepository {
  /// Get list of sex offenders in Putnam County
  Future<List<SexOffender>> getPutnamOffenders();

  /// Get filtered and sorted list of sex offenders
  Future<List<SexOffender>> getFilteredOffenders(SexOffenderFilters filters);
}

/// Supabase implementation of SexOffenderRepository
class SupabaseSexOffenderRepository implements SexOffenderRepository {
  SupabaseSexOffenderRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SexOffender>> getPutnamOffenders() async {
    return getFilteredOffenders(
      SexOffenderFilters(
        sortBy: SortField.name,
        sortDirection: SortDirection.ascending,
      ),
    );
  }

  @override
  Future<List<SexOffender>> getFilteredOffenders(
    SexOffenderFilters filters,
  ) async {
    try {
      var query = _client
          .from(AppConfig.sexOffendersTable)
          .select(
            'first_name, middle_name, last_name, suffix_name, perm_address_line_1, perm_address_line_2, perm_city, perm_state, perm_zip5, perm_county, image_url, birth_date, status',
          )
          .eq('perm_state', 'FL')
          .ilike('perm_county', 'Putnam%') as dynamic;

      // Apply city filter
      if (filters.selectedCity != null && filters.selectedCity!.isNotEmpty) {
        query = query.ilike('perm_city', filters.selectedCity!) as dynamic;
      }

      // Apply search query (name, city, or address)
      if (filters.searchQuery.isNotEmpty) {
        final String searchLower = filters.searchQuery.toLowerCase();
        query = query.or(
          'first_name.ilike.%$searchLower%,last_name.ilike.%$searchLower%,perm_city.ilike.%$searchLower%,perm_address_line_1.ilike.%$searchLower%',
        ) as dynamic;
      }

      // Apply sorting
      switch (filters.sortBy) {
        case SortField.name:
          query = query.order(
            'last_name',
            ascending: filters.sortDirection == SortDirection.ascending,
          ) as dynamic;
          break;
        case SortField.city:
          query = query.order(
            'perm_city',
            ascending: filters.sortDirection == SortDirection.ascending,
          ) as dynamic;
          break;
        case SortField.age:
          // For age sorting, we'll sort by birth_date descending for ascending age
          // (older birth date = older person)
          query = query.order(
            'birth_date',
            ascending: filters.sortDirection == SortDirection.descending,
          ) as dynamic;
          break;
        case SortField.none:
          query = query.order('last_name', ascending: true) as dynamic;
          break;
      }

      final List<dynamic> rows = await query
          .timeout(AppConfig.defaultTimeout) as List<dynamic>;

      final List<SexOffender> offenders = rows
          .map((dynamic r) => _parseSexOffender(r as Map<String, dynamic>))
          .toList();

      // For age sorting, we need to sort in memory since we calculate age
      if (filters.sortBy == SortField.age) {
        offenders.sort((SexOffender a, SexOffender b) {
          final int ageA = a.birthDate != null
              ? DateTime.now().difference(a.birthDate!).inDays ~/ 365
              : 0;
          final int ageB = b.birthDate != null
              ? DateTime.now().difference(b.birthDate!).inDays ~/ 365
              : 0;

          if (filters.sortDirection == SortDirection.ascending) {
            return ageA.compareTo(ageB);
          } else {
            return ageB.compareTo(ageA);
          }
        });
      }

      return offenders;
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to fetch sex offenders', e);
      }
      throw DatabaseException('Failed to load sex offenders: $e');
    }
  }

  /// Parse sex offender from raw data
  SexOffender _parseSexOffender(Map<String, dynamic> data) {
    try {
      // Construct full name
      final String firstName = (data['first_name'] as String?) ?? '';
      final String middleName = (data['middle_name'] as String?) ?? '';
      final String lastName = (data['last_name'] as String?) ?? '';
      final String suffix = (data['suffix_name'] as String?) ?? '';

      // Format name as "Last, First Middle Suffix"
      final List<String> nameParts = <String>[];
      if (lastName.isNotEmpty) {
        nameParts.add(lastName);
        if (firstName.isNotEmpty || middleName.isNotEmpty || suffix.isNotEmpty) {
          nameParts.add(',');
        }
      }
      if (firstName.isNotEmpty) {
        nameParts.add(firstName);
      }
      if (middleName.isNotEmpty) {
        nameParts.add(middleName);
      }
      if (suffix.isNotEmpty) {
        nameParts.add(suffix);
      }
      final String fullName = nameParts.join(' ');

      // Construct address
      final String line1 = (data['perm_address_line_1'] as String?) ?? '';
      final String line2 = (data['perm_address_line_2'] as String?) ?? '';
      final String city = (data['perm_city'] as String?) ?? '';
      final String state = (data['perm_state'] as String?) ?? '';
      final String zip = (data['perm_zip5'] as String?) ?? '';

      final List<String> addressParts = <String>[
        if (line1.isNotEmpty) line1,
        if (line2.isNotEmpty) line2,
        if (city.isNotEmpty) city,
        if (state.isNotEmpty) state,
        if (zip.isNotEmpty) zip,
      ];
      final String fullAddress = addressParts.join(', ');

      // Parse birth date
      DateTime? birthDate;
      final dynamic birthDateField = data['birth_date'];
      if (birthDateField != null) {
        if (birthDateField is DateTime) {
          birthDate = birthDateField;
        } else {
          birthDate = DateTime.tryParse(birthDateField.toString());
        }
      }

      return SexOffender(
        id: null, // ID not available in fl_sor table
        name: fullName.isNotEmpty ? fullName : 'Unknown',
        address:
            fullAddress.isNotEmpty ? fullAddress : 'Address not available',
        city: city.isNotEmpty ? city : 'City not available',
        imageUrl: data['image_url'] as String?,
        birthDate: birthDate,
        status: data['status'] as String?,
      );
    } catch (e) {
      throw DataParsingException('Failed to parse sex offender data', data);
    }
  }
}

