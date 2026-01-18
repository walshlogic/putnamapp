/// Represents a user review of a place
class Review {
  Review({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    required this.comment,
    this.title,
    this.userName,
    this.userPhotoUrl,
    this.visitDate,
    this.recommended = true,
    this.helpfulCount = 0,
    this.isAnonymous = false,
    this.isApproved = false,
    this.isFlagged = false,
    this.flaggedReason,
    this.ownerResponse,
    this.ownerRespondedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String placeId;
  final String userId;
  final int rating; // 1-5 stars
  final String comment;
  final String? title;
  
  // User info (from join with user_profiles)
  final String? userName;
  final String? userPhotoUrl;
  
  // Review details
  final DateTime? visitDate;
  final bool recommended;
  final int helpfulCount;
  final bool isAnonymous;
  
  // Moderation
  final bool isApproved;
  final bool isFlagged;
  final String? flaggedReason;
  
  // Owner response
  final String? ownerResponse;
  final DateTime? ownerRespondedAt;
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Get time ago string
  String get timeAgo {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Parse from Supabase JSON
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      placeId: json['place_id'] as String,
      userId: json['user_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      title: json['title'] as String?,
      userName: json['user_name'] as String?,
      userPhotoUrl: json['user_photo_url'] as String?,
      visitDate: json['visit_date'] != null
          ? DateTime.parse(json['visit_date'] as String)
          : null,
      recommended: json['recommended'] as bool? ?? true,
      helpfulCount: json['helpful_count'] as int? ?? 0,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      isFlagged: json['is_flagged'] as bool? ?? false,
      flaggedReason: json['flagged_reason'] as String?,
      ownerResponse: json['owner_response'] as String?,
      ownerRespondedAt: json['owner_responded_at'] != null
          ? DateTime.parse(json['owner_responded_at'] as String)
          : null,
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
      'place_id': placeId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'title': title,
      'visit_date': visitDate?.toIso8601String(),
      'recommended': recommended,
      'helpful_count': helpfulCount,
      'is_anonymous': isAnonymous,
      'is_approved': isApproved,
      'is_flagged': isFlagged,
      'flagged_reason': flaggedReason,
      'owner_response': ownerResponse,
      'owner_responded_at': ownerRespondedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Review copyWith({
    String? id,
    String? placeId,
    String? userId,
    int? rating,
    String? comment,
    String? title,
    String? userName,
    String? userPhotoUrl,
    DateTime? visitDate,
    bool? recommended,
    int? helpfulCount,
    bool? isApproved,
    bool? isFlagged,
    String? flaggedReason,
    String? ownerResponse,
    DateTime? ownerRespondedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      title: title ?? this.title,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      visitDate: visitDate ?? this.visitDate,
      recommended: recommended ?? this.recommended,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isApproved: isApproved ?? this.isApproved,
      isFlagged: isFlagged ?? this.isFlagged,
      flaggedReason: flaggedReason ?? this.flaggedReason,
      ownerResponse: ownerResponse ?? this.ownerResponse,
      ownerRespondedAt: ownerRespondedAt ?? this.ownerRespondedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

