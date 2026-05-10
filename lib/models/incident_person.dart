/// A person tagged to an incident. At least one of [bookingNo], [mniNo], or
/// [label] must be non-null/non-empty (enforced by a CHECK constraint on the
/// `incident_persons` table). Free-form input — the app doesn't validate the
/// booking # or MNI # against any other table.
class IncidentPerson {
  IncidentPerson({
    required this.id,
    required this.incidentId,
    this.bookingNo,
    this.mniNo,
    this.label,
    this.sortOrder = 0,
    this.createdAt,
  });

  final String id;
  final String incidentId;
  final String? bookingNo;
  final String? mniNo;
  final String? label;
  final int sortOrder;
  final DateTime? createdAt;

  /// Best one-line display for list views.
  String get displayName {
    if (label != null && label!.trim().isNotEmpty) return label!.trim();
    if (bookingNo != null && bookingNo!.isNotEmpty) return 'Booking $bookingNo';
    if (mniNo != null && mniNo!.isNotEmpty) return 'MNI $mniNo';
    return '(unnamed)';
  }

  factory IncidentPerson.fromJson(Map<String, dynamic> json) {
    return IncidentPerson(
      id: json['id'] as String,
      incidentId: json['incident_id'] as String,
      bookingNo: json['booking_no'] as String?,
      mniNo: json['mni_no'] as String?,
      label: json['label'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJsonForWrite() {
    return <String, dynamic>{
      'incident_id': incidentId,
      'booking_no': bookingNo,
      'mni_no': mniNo,
      'label': label,
      'sort_order': sortOrder,
    };
  }
}
