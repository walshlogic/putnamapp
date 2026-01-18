import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/news_article.dart';
import '../models/news_filters.dart';
import '../repositories/news_repository.dart';
import '../services/supabase_service.dart';

/// Provider for NewsRepository
final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return SupabaseNewsRepository(SupabaseService.client);
});

/// Provider for filtered news articles with pagination
final newsArticlesProvider = FutureProvider.family<
    NewsArticleResults,
    NewsFilters
>((ref, filters) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.getArticles(filters);
});

/// Provider for articles by category
final newsArticlesByCategoryProvider = FutureProvider.family<
    List<NewsArticle>,
    String
>((ref, category) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.getArticlesByCategory(category);
});

/// Provider for recent articles (last 24 hours)
final recentNewsArticlesProvider = FutureProvider<List<NewsArticle>>((ref) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.getRecentArticles();
});

/// Provider for single article by ID
final newsArticleByIdProvider = FutureProvider.family<
    NewsArticle?,
    String
>((ref, id) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.getArticleById(id);
});

