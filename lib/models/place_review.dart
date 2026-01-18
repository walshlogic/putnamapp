/// Represents a user review for a place
class PlaceReview {
  PlaceReview({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    this.title,
    required this.comment,
    this.photoUrls = const <String>[],
    this.isApproved = false,
    this.isFlagged = false,
    this.flagReason,
    this.helpfulCount = 0,
    this.userName,
    this.userPhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String placeId;
  final String userId;
  final int rating; // 1-5
  final String? title;
  final String comment;
  final List<String> photoUrls;
  
  // Moderation
  final bool isApproved;
  final bool isFlagged;
  final String? flagReason;
  
  // Engagement
  final int helpfulCount;
  
  // User info (joined from user_profiles)
  final String? userName;
  final String? userPhotoUrl;
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Get star icons for rating display
  String get starIcons {
    return '⭐' * rating;
  }

  /// Get formatted date
  String get formattedDate {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }

  /// Parse from Supabase JSON
  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    return PlaceReview(
      id: json['id'] as String,
      placeId: json['place_id'] as String,
      userId: json['user_id'] as String,
      rating: json['rating'] as int,
      title: json['title'] as String?,
      comment: json['comment'] as String,
      photoUrls: json['photo_urls'] != null
          ? List<String>.from(json['photo_urls'] as List)
          : <String>[],
      isApproved: json['is_approved'] as bool? ?? false,
      isFlagged: json['is_flagged'] as bool? ?? false,
      flagReason: json['flag_reason'] as String?,
      helpfulCount: json['helpful_count'] as int? ?? 0,
      userName: json['user_name'] as String?,
      userPhotoUrl: json['user_photo_url'] as String?,
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
      'title': title,
      'comment': comment,
      'photo_urls': photoUrls,
      'is_approved': isApproved,
      'is_flagged': isFlagged,
      'flag_reason': flagReason,
      'helpful_count': helpfulCount,
    };
  }
}

