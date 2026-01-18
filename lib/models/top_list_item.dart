/// Represents an item in a Top 100 list
class TopListItem {
  TopListItem({
    required this.rank,
    required this.label,
    required this.count,
    this.subtitle,
    this.extraData,
  });

  final int rank; // 1-100
  final String label; // Name, charge, etc.
  final int count; // Number of bookings, charges, etc.
  final String? subtitle; // Optional secondary info
  final Map<String, dynamic>? extraData; // Additional data for navigation

  /// Format count with commas
  String get formattedCount => count.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

/// Category types for Top 100 lists
enum TopListCategory {
  arrestedPersons,
  felonyCharges,
  misdemeanorCharges,
  allCharges,
  bookingDays,
}

/// Extension to get display info for each category
extension TopListCategoryX on TopListCategory {
  String get title {
    switch (this) {
      case TopListCategory.arrestedPersons:
        return 'TOP 100 ARRESTED PERSONS';
      case TopListCategory.felonyCharges:
        return 'TOP 100 FELONY CHARGES';
      case TopListCategory.misdemeanorCharges:
        return 'TOP 100 MISDEMEANOR CHARGES';
      case TopListCategory.allCharges:
        return 'TOP 100 ALL CHARGES';
      case TopListCategory.bookingDays:
        return 'TOP 100 BOOKING DAYS';
    }
  }

  String get subtitle {
    switch (this) {
      case TopListCategory.arrestedPersons:
        return 'Most frequently booked individuals';
      case TopListCategory.felonyCharges:
        return 'Most common felony charges';
      case TopListCategory.misdemeanorCharges:
        return 'Most common misdemeanor charges';
      case TopListCategory.allCharges:
        return 'Most common charges overall';
      case TopListCategory.bookingDays:
        return 'Days with the most bookings';
    }
  }

  String get countLabel {
    switch (this) {
      case TopListCategory.arrestedPersons:
        return 'Bookings';
      case TopListCategory.felonyCharges:
      case TopListCategory.misdemeanorCharges:
      case TopListCategory.allCharges:
        return 'Charges';
      case TopListCategory.bookingDays:
        return 'Bookings';
    }
  }
}

