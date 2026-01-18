import 'package:intl/intl.dart';

/// Represents a news article from various sources
class NewsArticle {
  NewsArticle({
    required this.id,
    required this.sourceId,
    required this.externalId,
    required this.title,
    this.description,
    this.content,
    required this.url,
    this.imageUrl,
    this.author,
    required this.publishedAt,
    this.category,
    this.tags,
    this.language,
    this.country,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sourceId;
  final String externalId;
  final String title;
  final String? description;
  final String? content;
  final String url;
  final String? imageUrl;
  final String? author;
  final DateTime publishedAt;
  final String? category;
  final List<String>? tags;
  final String? language;
  final String? country;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Formatted published date string
  String get publishedDateString =>
      DateFormat('MMM dd, yyyy').format(publishedAt);

  /// Formatted published time string (e.g., "2 hours ago")
  String get publishedTimeAgo {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(publishedAt);

    if (difference.inDays > 7) {
      return publishedDateString;
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

  /// Title truncated to 80 characters for display
  String get titleShort {
    if (title.length <= 80) {
      return title;
    }
    return '${title.substring(0, 77)}...';
  }

  /// Description truncated to 150 characters
  String? get descriptionShort {
    if (description == null || description!.isEmpty) {
      return null;
    }
    if (description!.length <= 150) {
      return description;
    }
    return '${description!.substring(0, 147)}...';
  }

  /// Category display name (capitalized)
  String get categoryDisplay {
    if (category == null || category!.isEmpty) {
      return 'General';
    }
    return category![0].toUpperCase() + category!.substring(1);
  }

  /// Check if article is recent (within last 24 hours)
  bool get isRecent {
    final DateTime cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return publishedAt.isAfter(cutoff);
  }

  /// Check if article has an image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Parse from Supabase data
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] as String,
      sourceId: json['source_id'] as String,
      externalId: json['external_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      content: json['content'] as String?,
      url: json['url'] as String,
      imageUrl: json['image_url'] as String?,
      author: json['author'] as String?,
      publishedAt: DateTime.parse(json['published_at'] as String),
      category: json['category'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      language: json['language'] as String?,
      country: json['country'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'source_id': sourceId,
      'external_id': externalId,
      'title': title,
      'description': description,
      'content': content,
      'url': url,
      'image_url': imageUrl,
      'author': author,
      'published_at': publishedAt.toIso8601String(),
      'category': category,
      'tags': tags,
      'language': language,
      'country': country,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Results wrapper for paginated news articles
class NewsArticleResults {
  NewsArticleResults({
    required this.articles,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<NewsArticle> articles;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages => (totalCount / pageSize).ceil();
  bool get hasMore => page < totalPages;
}

