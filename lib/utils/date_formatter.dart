import 'package:intl/intl.dart';

/// Utility class for date formatting
class DateFormatter {
  DateFormatter._(); // Private constructor to prevent instantiation

  /// Format a date as booking date string (MM/dd/yy @ h:mm AM/PM)
  static String bookingDate(DateTime date) {
    return DateFormat('MM/dd/yy @ h:mm a').format(date.toLocal());
  }

  /// Format a date as short date (MM/dd/yy)
  static String shortDate(DateTime date) {
    return DateFormat('MM/dd/yy').format(date.toLocal());
  }

  /// Format a date as full date (MMMM d, yyyy)
  static String fullDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date.toLocal());
  }

  /// Format a date as time only (h:mm AM/PM)
  static String timeOnly(DateTime date) {
    return DateFormat('h:mm a').format(date.toLocal());
  }

  /// Format a date as day of week (Monday, Tuesday, etc.)
  static String dayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date.toLocal());
  }

  /// Format a date as short day of week (Mon, Tue, etc.)
  static String shortDayOfWeek(DateTime date) {
    return DateFormat('EEE').format(date.toLocal());
  }

  /// Format a date relative to now (e.g., "2 hours ago")
  static String timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);

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
}

