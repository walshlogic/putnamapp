/// Discriminated union of attachment kinds — either an external URL
/// (YouTube link, news article, social media post) or a file uploaded
/// into the `incident-media` Supabase storage bucket.
enum IncidentAttachmentKind { url, file }

/// User-facing tag for what an attachment is. Stored in the DB as
/// `display_type` (CHECK constraint). The repository auto-suggests one
/// at create time based on MIME/URL; the user can override via the
/// edit-attachment dialog.
class IncidentDisplayType {
  IncidentDisplayType._();

  static const String video = 'video';
  static const String audio = 'audio';
  static const String image = 'image';
  static const String document = 'document';
  static const String news = 'news';
  static const String social = 'social';
  static const String other = 'other';

  /// In rough order of usefulness for human labelling.
  static const List<String> all = <String>[
    video,
    audio,
    image,
    document,
    news,
    social,
    other,
  ];

  static String label(String value) {
    switch (value) {
      case video:
        return 'Video';
      case audio:
        return 'Audio';
      case image:
        return 'Image';
      case document:
        return 'Document';
      case news:
        return 'News';
      case social:
        return 'Social';
      case other:
      default:
        return 'Other';
    }
  }
}

class IncidentAttachment {
  IncidentAttachment({
    required this.id,
    required this.incidentId,
    required this.kind,
    required this.url,
    required this.displayType,
    this.title,
    this.bucketPath,
    this.mimeType,
    this.fileSize,
    this.sortOrder = 0,
    this.createdAt,
  });

  final String id;
  final String incidentId;
  final IncidentAttachmentKind kind;
  final String url;

  /// User-facing tag for this attachment. One of the IncidentDisplayType
  /// constants. Always non-null (DB CHECK + NOT NULL); defaults to 'other'
  /// for ambiguous content.
  final String displayType;

  /// Required in the UI; nullable in the DB to keep legacy rows valid.
  final String? title;

  final String? bucketPath;
  final String? mimeType;
  final int? fileSize;
  final int sortOrder;
  final DateTime? createdAt;

  // ----- convenience predicates derived from displayType --------
  bool get isVideo => displayType == IncidentDisplayType.video;
  bool get isAudio => displayType == IncidentDisplayType.audio;
  bool get isImage => displayType == IncidentDisplayType.image;
  bool get isPdf => displayType == IncidentDisplayType.document &&
      (mimeType == 'application/pdf' || url.toLowerCase().endsWith('.pdf'));

  /// Best label to show — title if set, otherwise a friendly fallback.
  String get displayLabel {
    final String? t = title;
    if (t != null && t.trim().isNotEmpty) return t.trim();
    if (kind == IncidentAttachmentKind.url) {
      try {
        final Uri uri = Uri.parse(url);
        if (uri.host.isNotEmpty) return uri.host;
      } catch (_) {}
      return url;
    }
    // For files: use the filename portion of bucket_path / url.
    final String fromBucket =
        (bucketPath ?? '').split('/').last;
    if (fromBucket.isNotEmpty) return fromBucket;
    return url.split('/').last;
  }

  /// Auto-suggest a display_type from a MIME or URL when the user
  /// hasn't picked one yet. Used by the repository.
  static String suggestDisplayType({String? mimeType, String? url}) {
    if (mimeType != null) {
      if (mimeType.startsWith('video/')) return IncidentDisplayType.video;
      if (mimeType.startsWith('audio/')) return IncidentDisplayType.audio;
      if (mimeType.startsWith('image/')) return IncidentDisplayType.image;
      if (mimeType == 'application/pdf') return IncidentDisplayType.document;
    }
    if (url != null) {
      final String u = url.toLowerCase();
      if (u.contains('youtube.com') ||
          u.contains('youtu.be') ||
          u.contains('vimeo.com')) {
        return IncidentDisplayType.video;
      }
      if (u.contains('facebook.com') ||
          u.contains('twitter.com') ||
          u.contains('x.com') ||
          u.contains('instagram.com') ||
          u.contains('tiktok.com')) {
        return IncidentDisplayType.social;
      }
    }
    return IncidentDisplayType.other;
  }

  factory IncidentAttachment.fromJson(Map<String, dynamic> json) {
    final String rawKind = json['kind'] as String;
    return IncidentAttachment(
      id: json['id'] as String,
      incidentId: json['incident_id'] as String,
      kind: rawKind == 'file'
          ? IncidentAttachmentKind.file
          : IncidentAttachmentKind.url,
      url: json['url'] as String,
      displayType: json['display_type'] as String? ?? IncidentDisplayType.other,
      title: json['title'] as String?,
      bucketPath: json['bucket_path'] as String?,
      mimeType: json['mime_type'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
