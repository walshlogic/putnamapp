import 'package:intl/intl.dart';

/// Represents a user comment tied to a booking/person.
class BookingComment {
  BookingComment({
    required this.id,
    required this.bookingNo,
    required this.personName,
    required this.userId,
    required this.comment,
    this.mniNo,
    this.bookingDate,
    this.createdAt,
    this.userName,
    this.userPhotoUrl,
  });

  final String id;
  final String bookingNo;
  final String personName;
  final String userId;
  final String comment;
  final String? mniNo;
  final DateTime? bookingDate;
  final DateTime? createdAt;
  final String? userName;
  final String? userPhotoUrl;

  factory BookingComment.fromJson(Map<String, dynamic> json) {
    return BookingComment(
      id: json['id'] as String,
      bookingNo: json['booking_no'] as String,
      personName: json['person_name'] as String,
      userId: json['user_id'] as String,
      comment: json['comment'] as String,
      mniNo: json['mni_no'] as String?,
      bookingDate: json['booking_date'] != null
          ? DateTime.parse(json['booking_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      userName: json['user_name'] as String?,
      userPhotoUrl: json['user_photo_url'] as String?,
    );
  }

  BookingComment copyWith({String? userName, String? userPhotoUrl}) {
    return BookingComment(
      id: id,
      bookingNo: bookingNo,
      personName: personName,
      userId: userId,
      comment: comment,
      mniNo: mniNo,
      bookingDate: bookingDate,
      createdAt: createdAt,
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
