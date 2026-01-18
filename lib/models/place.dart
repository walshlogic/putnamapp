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

  /// Check if place is open now (simplified version)
  bool get isOpenNow {
    if (hours == null) return false;
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final todayHours = hours![dayName.toLowerCase()];
    if (todayHours == null || todayHours == 'Closed') return false;
    // TODO: Parse hours and check if current time is within range
    return true; // Simplified for now
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

