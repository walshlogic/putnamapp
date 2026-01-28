import 'package:intl/intl.dart';

/// Represents a user comment tied to a booking/person.
class BookingComment {
  BookingComment({
    required this.id,
    required this.bookingNo,
    required this.personName,
    required this.userId,
    required this.comment,
    required this.rootCommentId,
    required this.isPublished,
    this.appUserId,
    this.mniNo,
    this.bookingDate,
    this.createdAt,
    this.parentCommentId,
    this.editedAt,
    this.isFlagged,
    this.flagReason,
    this.flaggedAt,
    this.flaggedReviewedAt,
    this.flaggedReviewOutcome,
    this.userName,
    this.userPhotoUrl,
  });

  final String id;
  final String bookingNo;
  final String personName;
  final String userId;
  final String comment;
  final String rootCommentId;
  final bool isPublished;
  final String? appUserId;
  final String? mniNo;
  final DateTime? bookingDate;
  final DateTime? createdAt;
  final String? parentCommentId;
  final DateTime? editedAt;
  final bool? isFlagged;
  final String? flagReason;
  final DateTime? flaggedAt;
  final DateTime? flaggedReviewedAt;
  final String? flaggedReviewOutcome;
  final String? userName;
  final String? userPhotoUrl;

  factory BookingComment.fromJson(Map<String, dynamic> json) {
    return BookingComment(
      id: json['id'] as String,
      bookingNo: json['booking_no'] as String,
      personName: json['person_name'] as String,
      userId: json['user_id'] as String,
      comment: json['comment'] as String,
      rootCommentId:
          (json['root_comment_id'] as String?) ?? (json['id'] as String),
      isPublished: json['is_published'] as bool? ?? true,
      appUserId: json['app_user_id'] as String?,
      mniNo: json['mni_no'] as String?,
      bookingDate: json['booking_date'] != null
          ? DateTime.parse(json['booking_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      parentCommentId: json['parent_comment_id'] as String?,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      isFlagged: json['is_flagged'] as bool?,
      flagReason: json['flag_reason'] as String?,
      flaggedAt: json['flagged_at'] != null
          ? DateTime.parse(json['flagged_at'] as String)
          : null,
      flaggedReviewedAt: json['flagged_reviewed_at'] != null
          ? DateTime.parse(json['flagged_reviewed_at'] as String)
          : null,
      flaggedReviewOutcome: json['flagged_review_outcome'] as String?,
      userName: json['user_name'] as String?,
      userPhotoUrl: json['user_photo_url'] as String?,
    );
  }

  BookingComment copyWith({
    String? userName,
    String? userPhotoUrl,
    String? appUserId,
  }) {
    return BookingComment(
      id: id,
      bookingNo: bookingNo,
      personName: personName,
      userId: userId,
      comment: comment,
      rootCommentId: rootCommentId,
      isPublished: isPublished,
      appUserId: appUserId ?? this.appUserId,
      mniNo: mniNo,
      bookingDate: bookingDate,
      createdAt: createdAt,
      parentCommentId: parentCommentId,
      editedAt: editedAt,
      isFlagged: isFlagged,
      flagReason: flagReason,
      flaggedAt: flaggedAt,
      flaggedReviewedAt: flaggedReviewedAt,
      flaggedReviewOutcome: flaggedReviewOutcome,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
    );
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    }
    return DateFormat('MM/dd/yy').format(createdAt!.toLocal());
  }
}
