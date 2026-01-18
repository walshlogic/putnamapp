import 'package:intl/intl.dart';

/// Extension methods for DateTime
extension DateTimeX on DateTime {
  /// Format as booking date string (MM/dd/yy @ h:mm AM/PM)
  String toBookingDateString() =>
      DateFormat('MM/dd/yy @ h:mm a').format(toLocal());

  /// Check if date is within the last 24 hours
  bool isWithin24Hours() {
    final DateTime cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return isAfter(cutoff);
  }

  /// Check if date is within the last N days
  bool isWithinDays(int days) {
    final DateTime cutoff = DateTime.now().subtract(Duration(days: days));
    return isAfter(cutoff);
  }

  /// Check if date is within the last N hours
  bool isWithinHours(int hours) {
    final DateTime cutoff = DateTime.now().subtract(Duration(hours: hours));
    return isAfter(cutoff);
  }

  /// Get a human-readable time ago string
  String timeAgo() {
    final Duration diff = DateTime.now().difference(this);
    if (diff.inDays > 365) {
      final int years = diff.inDays ~/ 365;
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 30) {
      final int months = diff.inDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Format as short date (MM/dd/yy)
  String toShortDateString() => DateFormat('MM/dd/yy').format(toLocal());

  /// Format as full date (MMMM d, yyyy)
  String toFullDateString() => DateFormat('MMMM d, yyyy').format(toLocal());
}

