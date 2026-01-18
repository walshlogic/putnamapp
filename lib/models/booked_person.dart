/// Represents a person who has been booked (aggregated across all bookings)
class BookedPerson {
  BookedPerson({
    required this.name,
    required this.mniNo,
    required this.totalBookings,
    required this.totalCharges,
    required this.firstBookingDate,
    required this.lastBookingDate,
    this.birthMonthLow,
    this.birthYearLow,
    this.birthMonthHigh,
    this.birthYearHigh,
    this.race,
    this.gender,
    this.photoUrl,
  });

  final String name; // Primary key
  final String mniNo; // Master Name Index Number
  final int totalBookings;
  final int totalCharges;
  final DateTime firstBookingDate;
  final DateTime lastBookingDate;

  // Calculated birth date range (approximate)
  final int? birthMonthLow; // 1-12
  final int? birthYearLow; // e.g., 1979
  final int? birthMonthHigh; // 1-12
  final int? birthYearHigh; // e.g., 1980

  // Most recent demographic data
  final String? race;
  final String? gender;
  final String? photoUrl; // Most recent photo

  /// Get approximate age as of today
  int? get approximateAge {
    if (birthYearHigh == null) return null;
    // Use the high (latest) birth year for conservative estimate
    final int currentYear = DateTime.now().year;
    return currentYear - birthYearHigh!;
  }

  /// Get birth date range as display string
  String get birthDateRangeDisplay {
    if (birthMonthLow == null || birthYearLow == null) return 'Unknown';
    if (birthMonthHigh == null || birthYearHigh == null) return 'Unknown';

    // Format month with leading zero
    String formatMonth(int month) => month.toString().padLeft(2, '0');

    // If same month and year, show as single value
    if (birthYearLow == birthYearHigh && birthMonthLow == birthMonthHigh) {
      return '${formatMonth(birthMonthLow!)}/$birthYearLow';
    }

    // If same year, ensure months are in correct order (low to high)
    if (birthYearLow == birthYearHigh) {
      final int earlierMonth = birthMonthLow! < birthMonthHigh! ? birthMonthLow! : birthMonthHigh!;
      final int laterMonth = birthMonthLow! > birthMonthHigh! ? birthMonthLow! : birthMonthHigh!;
      return '${formatMonth(earlierMonth)}/$birthYearLow - ${formatMonth(laterMonth)}/$birthYearHigh';
    }

    // Different years - show as-is with proper formatting
    return '${formatMonth(birthMonthLow!)}/$birthYearLow - ${formatMonth(birthMonthHigh!)}/$birthYearHigh';
  }

  /// Convert to map for Supabase insertion
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mni_no': mniNo,
      'total_bookings': totalBookings,
      'total_charges': totalCharges,
      'first_booking_date': firstBookingDate.toIso8601String(),
      'last_booking_date': lastBookingDate.toIso8601String(),
      'birth_month_low': birthMonthLow,
      'birth_year_low': birthYearLow,
      'birth_month_high': birthMonthHigh,
      'birth_year_high': birthYearHigh,
      'race': race,
      'gender': gender,
      'photo_url': photoUrl,
      'calculated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create from Supabase data
  factory BookedPerson.fromJson(Map<String, dynamic> json) {
    return BookedPerson(
      name: json['name'] as String,
      mniNo: (json['mni_no'] as String?) ?? '',
      totalBookings: json['total_bookings'] as int,
      totalCharges: json['total_charges'] as int,
      firstBookingDate: DateTime.parse(json['first_booking_date'] as String),
      lastBookingDate: DateTime.parse(json['last_booking_date'] as String),
      birthMonthLow: json['birth_month_low'] as int?,
      birthYearLow: json['birth_year_low'] as int?,
      birthMonthHigh: json['birth_month_high'] as int?,
      birthYearHigh: json['birth_year_high'] as int?,
      race: json['race'] as String?,
      gender: json['gender'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

