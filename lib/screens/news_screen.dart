import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../extensions/build_context_extensions.dart';
import '../models/news_filters.dart';
import '../providers/news_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  int _currentPage = 1;
  final int _pageSize = 20;

  // Search debounce timer
  DateTime _lastSearchUpdate = DateTime.now();

  // Available categories
  final List<String> _categories = [
    'all',
    'general',
    'technology',
    'business',
    'health',
    'science',
    'sports',
    'entertainment',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final DateTime now = DateTime.now();
    _lastSearchUpdate = now;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_lastSearchUpdate == now && mounted) {
        setState(() {
          _searchQuery = value;
          _currentPage = 1;
        });
      }
    });
  }

  NewsFilters _getCurrentFilters() {
    return NewsFilters(
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      page: _currentPage,
      pageSize: _pageSize,
    );
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = null;
      _currentPage = 1;
    });
  }

  Future<void> _openArticle(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open article')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final filters = _getCurrentFilters();
    final articlesAsync = ref.watch(newsArticlesProvider(filters));

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          // Search and Category Filter Bar
          Container(
            color: appColors.lightPurple,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search news...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Category chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category ||
                          (_selectedCategory == null && category == 'all');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : null;
                              _currentPage = 1;
                            });
                          },
                          selectedColor: appColors.accentOrange,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : appColors.textDark,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Articles list
          Expanded(
            child: articlesAsync.when(
              data: (results) {
                if (results.articles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: appColors.textMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'NO ARTICLES FOUND',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: appColors.textDark,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty ||
                            (_selectedCategory != null && _selectedCategory != 'all'))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: _resetFilters,
                              child: const Text('Clear filters'),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(newsArticlesProvider(filters));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.articles.length + (results.hasMore ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == results.articles.length) {
                        // Load more button
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _currentPage++;
                                });
                              },
                              child: const Text('Load More'),
                            ),
                          ),
                        );
                      }

                      final article = results.articles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _openArticle(article.url),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Image (if available)
                              if (article.hasImage)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    article.imageUrl!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),

                              // Content
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    // Category badge
                                    if (article.category != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Chip(
                                          label: Text(
                                            article.categoryDisplay,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          backgroundColor: appColors.accentOrange.withValues(alpha: 0.2),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),

                                    // Title
                                    Text(
                                      article.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Description
                                    if (article.description != null &&
                                        article.description!.isNotEmpty)
                                      Text(
                                        article.descriptionShort ?? article.description!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: appColors.textMedium,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                    const SizedBox(height: 12),

                                    // Footer: Author and date
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        if (article.author != null &&
                                            article.author!.isNotEmpty)
                                          Expanded(
                                            child: Text(
                                              article.author!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: appColors.textMedium,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        Text(
                                          article.publishedTimeAgo,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: appColors.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: appColors.accentOrange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ERROR LOADING NEWS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: appColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(color: appColors.textMedium),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(newsArticlesProvider(filters));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}

