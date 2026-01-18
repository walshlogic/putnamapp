import 'package:intl/intl.dart';

/// Represents detailed charge information for a booking
class ChargeDetail {
  ChargeDetail({
    required this.charge,
    required this.statute,
    required this.caseNumber,
    required this.degree,
    required this.level,
    required this.bond,
  });

  final String charge;
  final String statute;
  final String caseNumber;
  final String degree;
  final String level;
  final String bond;

  /// Convert degree code to full text (always uppercase)
  String get degreeText {
    switch (degree.toUpperCase()) {
      case 'F':
        return 'FIRST';
      case 'S':
        return 'SECOND';
      case 'T':
        return 'THIRD';
      default:
        return degree.isNotEmpty ? degree.toUpperCase() : 'N/A';
    }
  }

  /// Convert level code to full text (always uppercase)
  String get levelText {
    switch (level.toUpperCase()) {
      case 'F':
        return 'FELONY';
      case 'M':
        return 'MISDEMEANOR';
      default:
        return level.isNotEmpty ? level.toUpperCase() : 'N/A';
    }
  }
}

/// Represents a jail booking record
class JailBooking {
  JailBooking({
    required this.bookingNo,
    required this.mniNo,
    required this.name,
    required this.status,
    required this.bookingDate,
    required this.ageOnBookingDate,
    required this.bondAmount,
    required this.addressGiven,
    required this.holdsText,
    required this.photoUrl,
    required this.releasedDate,
    required this.race,
    required this.gender,
    required this.charges,
    required this.chargeDetails,
  });

  final String bookingNo;
  final String mniNo;
  final String name;
  final String status;
  final DateTime bookingDate;
  final int? ageOnBookingDate;
  final String bondAmount;
  final String addressGiven;
  final String holdsText;
  final String photoUrl;
  final DateTime? releasedDate;
  final String race;
  final String gender;
  final List<String> charges; // Simple list for list view
  final List<ChargeDetail> chargeDetails; // Detailed list for detail view

  /// Formatted booking date string
  String get bookingDateString =>
      DateFormat('MM/dd/yy @ h:mm a').format(bookingDate.toLocal());

  /// Check if booking is within the last 24 hours
  bool isWithin24Hours() {
    final DateTime cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return bookingDate.isAfter(cutoff);
  }
}

