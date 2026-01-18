/// Hierarchical charge statistics by level and degree
class ChargesByLevelAndDegree {
  ChargesByLevelAndDegree({
    required this.level,
    required this.totalCount,
    required this.byDegree,
  });

  final String level; // FELONY, MISDEMEANOR, etc.
  final int totalCount;
  final Map<String, int> byDegree; // {FIRST: 50, SECOND: 100, ...}

  /// Get degrees sorted with First, Second, Third prioritized, then alphabetical
  List<MapEntry<String, int>> get degreesSorted {
    final entries = byDegree.entries.toList();
    
    entries.sort((a, b) {
      const orderedDegrees = ['FIRST', 'SECOND', 'THIRD'];
      
      final aIndex = orderedDegrees.indexOf(a.key);
      final bIndex = orderedDegrees.indexOf(b.key);
      
      if (aIndex != -1 && bIndex != -1) {
        return aIndex.compareTo(bIndex);
      }
      if (aIndex != -1) return -1;
      if (bIndex != -1) return 1;
      
      return a.key.compareTo(b.key);
    });
    
    return entries;
  }
}

/// Statistics for a specific law enforcement agency
class AgencyStats {
  AgencyStats({
    required this.agencyId,
    required this.agencyName,
    required this.totalBookings,
    required this.totalCharges,
    required this.bookingsByYear,
    required this.bookingsByGender,
    required this.bookingsByRace,
    required this.chargesByLevelAndDegree,
    required this.uniquePersons,
    required this.averageChargesPerBooking,
  });

  final String agencyId;
  final String agencyName;
  final int totalBookings;
  final int totalCharges;
  final Map<int, int> bookingsByYear; // {2025: 150, 2024: 1200, ...}
  final Map<String, int> bookingsByGender; // {MALE: 800, FEMALE: 200, ...}
  final Map<String, int> bookingsByRace; // {WHITE: 500, BLACK: 300, ...}
  final List<ChargesByLevelAndDegree> chargesByLevelAndDegree; // Hierarchical structure
  final int uniquePersons;
  final double averageChargesPerBooking;

  /// Get top N items from a map sorted by count
  List<MapEntry<String, int>> getTopItems(
    Map<String, int> map,
    int limit,
  ) {
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Get years sorted descending
  List<MapEntry<int, int>> get yearsSorted {
    final entries = bookingsByYear.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  /// Get charges by level sorted (FELONY first, MISDEMEANOR second, then alphabetical)
  List<ChargesByLevelAndDegree> get chargesByLevelSorted {
    final sorted = List<ChargesByLevelAndDegree>.from(chargesByLevelAndDegree);
    
    sorted.sort((a, b) {
      const orderedLevels = ['FELONY', 'MISDEMEANOR'];
      
      final aIndex = orderedLevels.indexOf(a.level);
      final bIndex = orderedLevels.indexOf(b.level);
      
      if (aIndex != -1 && bIndex != -1) {
        return aIndex.compareTo(bIndex);
      }
      if (aIndex != -1) return -1;
      if (bIndex != -1) return 1;
      
      return a.level.compareTo(b.level);
    });
    
    return sorted;
  }
}

