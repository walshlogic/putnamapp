/// Route path constants for the application
class RoutePaths {
  RoutePaths._(); // Private constructor to prevent instantiation

  // Auth routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String tierSelection = '/tier-selection';

  // Main app routes
  static const String home = '/';
  static const String bookings = '/bookings';
  static const String bookingDetail = '/booking-detail';
  static const String bookingPhotoProgression = '/booking-photo-progression';
  static const String bookingCommentCreate = '/booking-comment-create';
  static const String weather = '/weather';
  static const String sexOffenders = '/sex-offenders';
  static const String sexOffenderDetail = '/sex-offender-detail';
  static const String lawOrder = '/law-order';
  static const String topTen = '/top-ten';
  static const String topListDetail = '/top-list-detail';
  static const String personChargeBreakdown = '/person-charge-breakdown';
  static const String personBookings = '/person-bookings';
  static const String peopleByCharge = '/people-by-charge';
  static const String bookingsByDate = '/bookings-by-date';
  static const String agencyStats = '/agency-stats';
  static const String agencyDetail = '/agency-detail';
  static const String about = '/about';
  static const String contact = '/contact';
  static const String dataUsage = '/data-usage';
  static const String privacy = '/privacy';
  static const String termsOfUse = '/terms-of-use';

  // Directory routes
  static const String directory = '/directory';
  static const String directoryCategory = '/directory/category';
  static const String placeDetail = '/place-detail';

  // Government routes
  static const String government = '/government';
  static const String governmentDetail = '/government-detail';

  // Clerk of Court routes
  static const String clerkOfCourt = '/clerk-of-court';
  static const String trafficCitations = '/traffic-citations';
  static const String trafficCitationDetail = '/traffic-citation-detail';
  static const String criminalBackHistory = '/criminal-back-history';
  static const String criminalBackHistoryDetail =
      '/criminal-back-history-detail';

  // News routes
  static const String news = '/news';
}
