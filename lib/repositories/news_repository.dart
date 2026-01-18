import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../exceptions/app_exceptions.dart';
import '../models/news_article.dart';
import '../models/news_filters.dart';

/// Abstract repository for news article operations
abstract class NewsRepository {
  /// Get news articles with filters and pagination
  Future<NewsArticleResults> getArticles(NewsFilters filters);

  /// Get a single article by ID
  Future<NewsArticle?> getArticleById(String id);

  /// Get articles by category
  Future<List<NewsArticle>> getArticlesByCategory(String category, {int limit = 20});

  /// Get recent articles (last 24 hours)
  Future<List<NewsArticle>> getRecentArticles({int limit = 20});
}

/// Supabase implementation of NewsRepository
class SupabaseNewsRepository implements NewsRepository {
  SupabaseNewsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<NewsArticleResults> getArticles(NewsFilters filters) async {
    try {
      dynamic query = _client
          .from(AppConfig.newsArticlesTable)
          .select('*');

      // Apply category filter
      if (filters.category != null && filters.category!.isNotEmpty) {
        query = query.eq('category', filters.category!.toLowerCase());
      }

      // Apply search query (full-text search on title and description)
      if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
        final searchTerm = filters.searchQuery!.trim();
        query = query.or(
          'title.ilike.%$searchTerm%,description.ilike.%$searchTerm%',
        );
      }

      // Order by published date (newest first)
      query = query.order('published_at', ascending: false);

      // Apply pagination
      final int from = (filters.page - 1) * filters.pageSize;
      final int to = from + filters.pageSize - 1;
      query = query.range(from, to);

      final List<dynamic> data = await query as List<dynamic>;

      final articles = data
          .map((json) => NewsArticle.fromJson(json as Map<String, dynamic>))
          .toList();

      // Estimate total count (if we got a full page, assume there are more)
      final int totalCount = articles.length == filters.pageSize
          ? articles.length * 100 // Estimate
          : articles.length;

      return NewsArticleResults(
        articles: articles,
        totalCount: totalCount,
        page: filters.page,
        pageSize: filters.pageSize,
      );
    } catch (e) {
      throw DatabaseException('Failed to fetch news articles', e);
    }
  }

  @override
  Future<NewsArticle?> getArticleById(String id) async {
    try {
      final response = await _client
          .from(AppConfig.newsArticlesTable)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return NewsArticle.fromJson(response);
    } catch (e) {
      throw DatabaseException('Failed to fetch article by ID', e);
    }
  }

  @override
  Future<List<NewsArticle>> getArticlesByCategory(
    String category, {
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from(AppConfig.newsArticlesTable)
          .select()
          .eq('category', category.toLowerCase())
          .order('published_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;

      return data
          .map((json) => NewsArticle.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch articles by category', e);
    }
  }

  @override
  Future<List<NewsArticle>> getRecentArticles({int limit = 20}) async {
    try {
      final DateTime cutoff = DateTime.now().subtract(const Duration(hours: 24));

      final response = await _client
          .from(AppConfig.newsArticlesTable)
          .select()
          .gte('published_at', cutoff.toIso8601String())
          .order('published_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;

      return data
          .map((json) => NewsArticle.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch recent articles', e);
    }
  }
}

