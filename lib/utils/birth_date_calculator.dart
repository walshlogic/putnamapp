/// Represents a birth date range (month and year only)
class BirthDateRange {
  BirthDateRange({
    required this.lowMonth,
    required this.lowYear,
    required this.highMonth,
    required this.highYear,
  });

  final int lowMonth; // 1-12
  final int lowYear; // e.g., 1979
  final int highMonth; // 1-12
  final int highYear; // e.g., 1980

  @override
  String toString() => 'Low: $lowMonth/$lowYear, High: $highMonth/$highYear';

  /// Convert to a comparable date (for intersection logic)
  DateTime get lowDate => DateTime(lowYear, lowMonth, 1);
  DateTime get highDate => DateTime(highYear, highMonth, 28); // Use 28 to be safe
}

/// Simplified booking data for birth date calculation
class BookingData {
  BookingData({
    required this.bookingDate,
    required this.ageAtBooking,
  });

  final DateTime bookingDate;
  final int? ageAtBooking;
}

/// Utility for calculating approximate birth date ranges from booking data
class BirthDateCalculator {
  BirthDateCalculator._();

  /// Calculate possible birth date range from a single booking
  ///
  /// Logic:
  /// If arrested on 02/10/2000 at age 20:
  /// - Earliest birth: 02/11/1979 (would turn 21 on 02/11/2000, so was 20 on arrest)
  /// - Latest birth: 02/10/1980 (would turn 20 on 02/10/2000, so was 20 on arrest)
  static BirthDateRange calculateRangeFromBooking({
    required DateTime bookingDate,
    required int ageAtBooking,
  }) {
    // Latest possible birth date: booking_date - age years
    // (Person turns 'age' on the booking date)
    final DateTime latestBirth = DateTime(
      bookingDate.year - ageAtBooking,
      bookingDate.month,
      bookingDate.day,
    );

    // Earliest possible birth date: booking_date - (age + 1) years + 1 day
    // (Person turned age+1 one day after booking)
    final DateTime earliestBirth = DateTime(
      bookingDate.year - (ageAtBooking + 1),
      bookingDate.month,
      bookingDate.day,
    ).add(const Duration(days: 1));

    return BirthDateRange(
      lowMonth: earliestBirth.month,
      lowYear: earliestBirth.year,
      highMonth: latestBirth.month,
      highYear: latestBirth.year,
    );
  }

  /// Calculate the intersection of multiple birth date ranges
  /// Returns the narrowest possible range based on all bookings
  static BirthDateRange? calculateIntersection(
    List<BirthDateRange> ranges,
  ) {
    if (ranges.isEmpty) return null;
    if (ranges.length == 1) return ranges.first;

    // Find the LATEST of all lower bounds (most restrictive early date)
    DateTime mostRestrictiveLow = ranges.first.lowDate;
    for (final range in ranges) {
      if (range.lowDate.isAfter(mostRestrictiveLow)) {
        mostRestrictiveLow = range.lowDate;
      }
    }

    // Find the EARLIEST of all upper bounds (most restrictive late date)
    DateTime mostRestrictiveHigh = ranges.first.highDate;
    for (final range in ranges) {
      if (range.highDate.isBefore(mostRestrictiveHigh)) {
        mostRestrictiveHigh = range.highDate;
      }
    }

    // Check if ranges actually intersect
    if (mostRestrictiveLow.isAfter(mostRestrictiveHigh)) {
      // No valid intersection (data inconsistency)
      return null;
    }

    return BirthDateRange(
      lowMonth: mostRestrictiveLow.month,
      lowYear: mostRestrictiveLow.year,
      highMonth: mostRestrictiveHigh.month,
      highYear: mostRestrictiveHigh.year,
    );
  }

  /// Calculate birth date range from multiple bookings for the same person
  static BirthDateRange? calculateFromBookings(
    List<BookingData> bookings,
  ) {
    final List<BirthDateRange> ranges = <BirthDateRange>[];

    for (final booking in bookings) {
      if (booking.ageAtBooking != null) {
        ranges.add(
          calculateRangeFromBooking(
            bookingDate: booking.bookingDate,
            ageAtBooking: booking.ageAtBooking!,
          ),
        );
      }
    }

    return calculateIntersection(ranges);
  }
}


