/// Discriminated union of attachment kinds — either an external URL
/// (YouTube link, news article, social media post) or a file uploaded
/// into the `incident-media` Supabase storage bucket.
enum IncidentAttachmentKind { url, file }

class IncidentAttachment {
  IncidentAttachment({
    required this.id,
    required this.incidentId,
    required this.kind,
    required this.url,
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
  final String? title;
  final String? bucketPath;
  final String? mimeType;
  final int? fileSize;
  final int sortOrder;
  final DateTime? createdAt;

  bool get isVideo {
    final String? m = mimeType;
    if (m != null && m.startsWith('video/')) return true;
    final String lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v');
  }

  bool get isImage {
    final String? m = mimeType;
    if (m != null && m.startsWith('image/')) return true;
    final String lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.webp');
  }

  bool get isPdf {
    if (mimeType == 'application/pdf') return true;
    return url.toLowerCase().endsWith('.pdf');
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

  Map<String, dynamic> toJsonForWrite() {
    return <String, dynamic>{
      'incident_id': incidentId,
      'kind': kind == IncidentAttachmentKind.file ? 'file' : 'url',
      'url': url,
      'title': title,
      'bucket_path': bucketPath,
      'mime_type': mimeType,
      'file_size': fileSize,
      'sort_order': sortOrder,
    };
  }
}
