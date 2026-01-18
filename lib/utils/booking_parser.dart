import '../config/app_config.dart';
import '../exceptions/app_exceptions.dart';
import '../models/booking.dart';
import '../services/supabase_service.dart';

/// Utility class for parsing booking data from Supabase
class BookingParser {
  BookingParser._(); // Private constructor to prevent instantiation

  /// Parse a booking from raw Supabase data
  static JailBooking parseBooking(Map<String, dynamic> data) {
    try {
      final String bookingNo = (data['booking_no'] as String?) ?? 'Unknown';
      final String mniNo = (data['mni_no'] as String?) ?? '';
      final String name = (data['name'] as String?) ?? bookingNo;
      final String status = (data['status'] as String?) ?? 'Unknown';
      final String bondAmount = (data['bond_amount'] as String?) ?? '';
      final String addressGiven = (data['address_given'] as String?) ?? '';
      final String holdsText = (data['holds_text'] as String?) ?? '';
      final String race = (data['race'] as String?) ?? '';
      final String gender = (data['gender'] as String?) ?? '';
      final int? ageOnBookingDate = data['age_on_booking_date'] as int?;

      // Parse charges
      final dynamic chargesField = data['charges'];
      final List<String> charges = <String>[];
      final List<ChargeDetail> chargeDetails = <ChargeDetail>[];

      if (chargesField is List) {
        for (final dynamic item in chargesField) {
          if (item is Map<String, dynamic>) {
            final String? chargeText = item['charge'] as String?;
            if (chargeText != null && chargeText.isNotEmpty) {
              charges.add(chargeText);
              chargeDetails.add(
                ChargeDetail(
                  charge: chargeText,
                  statute: (item['statute'] as String?) ?? '',
                  caseNumber: (item['case_number'] as String?) ?? '',
                  degree: (item['degree'] as String?) ?? '',
                  level: (item['level'] as String?) ?? '',
                  bond: (item['bond'] as String?) ?? '',
                ),
              );
            }
          } else if (item != null) {
            charges.add(item.toString());
          }
        }
      }

      // Parse booking date
      final dynamic rawDate = data['booking_date'] ?? data['booked_at'];
      final DateTime bookingDate = _parseDateTime(rawDate);

      // Parse released date
      DateTime? releasedDate;
      final dynamic releasedRaw = data['released_date'];
      if (releasedRaw != null) {
        releasedDate = _parseDateTime(releasedRaw);
      }

      // Prefer photo_url from the DB (source site), fall back to storage bucket
      final String? dbPhotoUrl = data['photo_url'] as String?;
      final String basePhotoUrl = (dbPhotoUrl != null && dbPhotoUrl.isNotEmpty)
          ? dbPhotoUrl
          : SupabaseService.client.storage
              .from(AppConfig.bookingPhotosBucket)
              .getPublicUrl('$bookingNo.jpg');
      final int cacheBuster = bookingDate.millisecondsSinceEpoch;
      final String separator = basePhotoUrl.contains('?') ? '&' : '?';
      final String photoUrl = '$basePhotoUrl${separator}v=$cacheBuster';

      return JailBooking(
        bookingNo: bookingNo,
        mniNo: mniNo,
        name: name,
        status: status,
        bookingDate: bookingDate,
        ageOnBookingDate: ageOnBookingDate,
        bondAmount: bondAmount,
        addressGiven: addressGiven,
        holdsText: holdsText,
        photoUrl: photoUrl,
        releasedDate: releasedDate,
        race: race,
        gender: gender,
        charges: charges,
        chargeDetails: chargeDetails,
      );
    } catch (e) {
      throw DataParsingException('Failed to parse booking data', data);
    }
  }

  /// Parse a DateTime from various formats
  static DateTime _parseDateTime(dynamic rawDate) {
    if (rawDate is DateTime) {
      return rawDate.toLocal();
    }

    final String dateString = (rawDate ?? '').toString();
    DateTime? dt = DateTime.tryParse(dateString);

    if (dt == null) {
      // Try normalizing the string format
      String normalized = dateString.replaceFirst(' ', 'T');

      // Handle timezone format variations
      if (normalized.endsWith('+00')) {
        normalized = '$normalized:00';
      } else if (RegExp(r'[\+\-]\d{4}$').hasMatch(normalized)) {
        normalized =
            normalized.replaceFirst(RegExp(r'([\+\-]\d{2})(\d{2})$'), r'$1:$2');
      }

      dt = DateTime.tryParse(normalized);
    }

    return (dt ?? DateTime.now()).toLocal();
  }

  /// Parse a list of bookings from raw Supabase data
  static List<JailBooking> parseBookingList(List<dynamic> rawData) {
    return rawData
        .map((dynamic item) {
          if (item is Map<String, dynamic>) {
            try {
              return parseBooking(item);
            } catch (e) {
              // Log error and skip this item
              return null;
            }
          }
          return null;
        })
        .whereType<JailBooking>()
        .toList();
  }
}

