/// Represents a place in the local directory
class Place {
  Place({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
    this.description,
    this.address,
    this.city = 'Palatka',
    this.state = 'FL',
    this.zipCode,
    this.phone,
    this.email,
    this.website,
    this.latitude,
    this.longitude,
    this.hours,
    this.priceRange,
    this.logoUrl,
    this.coverPhotoUrl,
    this.photoUrls = const <String>[],
    this.isVerified = false,
    this.isActive = true,
    this.viewCount = 0,
    this.reviewCount = 0,
    this.averageRating = 0.0,
    this.favoriteCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String? subcategory;
  final String? description;
  
  // Contact
  final String? address;
  final String city;
  final String state;
  final String? zipCode;
  final String? phone;
  final String? email;
  final String? website;
  
  // Location
  final double? latitude;
  final double? longitude;
  
  // Operating details
  final Map<String, dynamic>? hours;
  final String? priceRange; // '$', '$$', '$$$', '$$$$'
  
  // Media
  final String? logoUrl;
  final String? coverPhotoUrl;
  final List<String> photoUrls;
  
  // Status
  final bool isVerified;
  final bool isActive;
  final int viewCount;
  
  // Aggregated stats (from join/view)
  final int reviewCount;
  final double averageRating;
  final int favoriteCount;
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Get full address string
  String get fullAddress {
    final List<String> parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    return parts.join(', ');
  }

  /// Get formatted phone number
  String? get formattedPhone {
    if (phone == null || phone!.isEmpty) return null;
    // Simple formatting: (386) 555-1234
    final digits = phone!.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return phone;
  }

  /// Check if place is open now based on the `hours` map.
  ///
  /// Supports common formats stored per day:
  /// - `"9:00 AM - 5:00 PM"` (12-hour with AM/PM)
  /// - `"09:00 - 17:00"` (24-hour)
  /// - `"11:00 AM - 2:00 PM, 5:00 PM - 9:00 PM"` (split shifts)
  /// - `"9:00 PM - 2:00 AM"` (overnight; matches if "now" is past close
  ///   on either calendar day in the range)
  /// - `"24 hours"`, `"24/7"`, `"Open 24 hours"` → always open
  /// - `"Closed"`, missing entry, unparseable values → closed
  bool get isOpenNow {
    if (hours == null) return false;
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday).toLowerCase();
    final raw = hours![dayName];
    if (raw is! String) return false;
    return _isOpenInString(raw, now);
  }

  static final RegExp _timeRe = RegExp(
    r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
    caseSensitive: false,
  );

  /// Public for testing — true when `now` falls within any range described
  /// by `hoursString` for the day. Returns false on unparseable input.
  static bool _isOpenInString(String hoursString, DateTime now) {
    final s = hoursString.trim();
    if (s.isEmpty) return false;
    final lower = s.toLowerCase();
    if (lower == 'closed') return false;
    if (lower.contains('24 hour') || lower == '24/7' || lower == 'open 24 hours') {
      return true;
    }
    final nowMinutes = now.hour * 60 + now.minute;
    // Multiple ranges separated by commas (split shifts).
    for (final range in s.split(',')) {
      // Accept hyphen, en-dash, em-dash, or " to "
      final parts = range.split(RegExp(r'\s*(?:-|–|—|\bto\b)\s*'));
      if (parts.length != 2) continue;
      final open = _parseTimeToMinutes(parts[0]);
      final close = _parseTimeToMinutes(parts[1]);
      if (open == null || close == null) continue;
      if (close > open) {
        if (nowMinutes >= open && nowMinutes < close) return true;
      } else {
        // Overnight (e.g. 9 PM - 2 AM): open OR before close on next day.
        if (nowMinutes >= open || nowMinutes < close) return true;
      }
    }
    return false;
  }

  /// Parses a time fragment into minutes-from-midnight. Returns null on
  /// failure. Accepts "9", "9:30", "9 AM", "09:30", "9:30 PM", etc.
  static int? _parseTimeToMinutes(String input) {
    final m = _timeRe.firstMatch(input.trim());
    if (m == null) return null;
    var hour = int.tryParse(m.group(1) ?? '');
    final minute = int.tryParse(m.group(2) ?? '0') ?? 0;
    final ampm = m.group(3)?.toLowerCase();
    if (hour == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    if (ampm == 'pm' && hour < 12) hour += 12;
    if (ampm == 'am' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  /// Parse from Supabase JSON
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String? ?? 'Palatka',
      state: json['state'] as String? ?? 'FL',
      zipCode: json['zip_code'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      hours: json['hours'] as Map<String, dynamic>?,
      priceRange: json['price_range'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      photoUrls: json['photo_urls'] != null
          ? List<String>.from(json['photo_urls'] as List)
          : <String>[],
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      viewCount: json['view_count'] as int? ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : 0.0,
      favoriteCount: json['favorite_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'phone': phone,
      'email': email,
      'website': website,
      'latitude': latitude,
      'longitude': longitude,
      'hours': hours,
      'price_range': priceRange,
      'logo_url': logoUrl,
      'cover_photo_url': coverPhotoUrl,
      'photo_urls': photoUrls,
      'is_verified': isVerified,
      'is_active': isActive,
      'view_count': viewCount,
    };
  }
}

/// Place categories
enum PlaceCategory {
  restaurant,
  retail,
  faith,
  entertainment,
  lodging,
  services,
  health,
  business,
  outdoors,
}

/// Extension for category display information
extension PlaceCategoryX on PlaceCategory {
  String get displayName {
    switch (this) {
      case PlaceCategory.restaurant:
        return 'Dining';
      case PlaceCategory.retail:
        return 'Shopping';
      case PlaceCategory.faith:
        return 'Faith';
      case PlaceCategory.entertainment:
        return 'Fun';
      case PlaceCategory.lodging:
        return 'Lodging';
      case PlaceCategory.services:
        return 'Services';
      case PlaceCategory.health:
        return 'Health';
      case PlaceCategory.business:
        return 'Business';
      case PlaceCategory.outdoors:
        return 'Outdoors';
    }
  }

  String get icon {
    switch (this) {
      case PlaceCategory.restaurant:
        return '🍽️';
      case PlaceCategory.retail:
        return '🏪';
      case PlaceCategory.faith:
        return '⛪';
      case PlaceCategory.entertainment:
        return '🎭';
      case PlaceCategory.lodging:
        return '🏨';
      case PlaceCategory.services:
        return '🔧';
      case PlaceCategory.health:
        return '🏥';
      case PlaceCategory.business:
        return '💼';
      case PlaceCategory.outdoors:
        return '🎣';
    }
  }

  String get subtitle {
    switch (this) {
      case PlaceCategory.restaurant:
        return 'Restaurants, Cafes, Bars';
      case PlaceCategory.retail:
        return 'Retail, Groceries, Specialty';
      case PlaceCategory.faith:
        return 'Churches & Worship';
      case PlaceCategory.entertainment:
        return 'Activities & Events';
      case PlaceCategory.lodging:
        return 'Hotels & Rentals';
      case PlaceCategory.services:
        return 'Auto, Home & More';
      case PlaceCategory.health:
        return 'Medical & Wellness';
      case PlaceCategory.business:
        return 'Banks, Legal & Real Estate';
      case PlaceCategory.outdoors:
        return 'Parks, Recreation & Fishing';
    }
  }

  String get value {
    return name;
  }
}

