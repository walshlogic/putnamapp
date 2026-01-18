/// Application-wide configuration constants
class AppConfig {
  // App Information
  static const String appName = 'PUTNAM.APP';
  static const String appSubtitle = 'LOCAL INFORMATION HUB';

  // Supabase Table Names
  static const String bookingsTable = 'recent_bookings_with_charges';
  static const String bookingStatsTable = 'booking_stats';
  static const String sexOffendersTable = 'fl_sor';
  static const String trafficCitationsTable = 'traffic_citations';
  static const String criminalBackHistoryTable = 'criminal_back_history';
  static const String newsArticlesTable = 'news_articles';
  static const String agencyStatsTable = 'agency_stats';

  // Supabase Storage Buckets
  static const String bookingPhotosBucket = 'pcso-booking-photos';

  // Time Range Durations
  static const Duration time24Hours = Duration(hours: 24);

  // Pagination
  static const int defaultPageSize =
      50; // Increased for better browsing experience
  static const int maxCountLimit = 10000;

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 12);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(seconds: 15);

  // Search
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);

  // Time Range Options
  static const String timeRange24Hours = '24HR';
  static const String timeRangeThisYear = '1 YEAR';
  static const String timeRange5Years = '5 YEARS';
  static const String timeRangeAll = 'ALL';

  // Sort Options
  static const String sortByDate = 'DATE';
  static const String sortByName = 'NAME';
  
  // Sort Order Options
  static const String sortOrderAsc = 'ASC';
  static const String sortOrderDesc = 'DESC';
  
  // Name Sort Options
  static const String nameSortByFirstName = 'FIRST_NAME';
  static const String nameSortByLastName = 'LAST_NAME';

  // Status Filter Options
  static const String statusAll = 'All';
  static const String statusInJail = 'In Jail';
  static const String statusReleased = 'Released';

  // Photo dimensions
  static const double photoRadius = 72.0;
  static const double thumbnailSize = 60.0;

  // Default Coordinates (Putnam County, Palatka FL)
  static const double defaultLatitude = 29.6486;
  static const double defaultLongitude = -81.6376;
}
