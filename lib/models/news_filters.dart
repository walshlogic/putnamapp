/// Filters for news article queries
class NewsFilters {
  const NewsFilters({
    this.category,
    this.searchQuery,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? category;
  final String? searchQuery;
  final int page;
  final int pageSize;

  NewsFilters copyWith({
    String? category,
    String? searchQuery,
    int? page,
    int? pageSize,
  }) {
    return NewsFilters(
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewsFilters &&
        other.category == category &&
        other.searchQuery == searchQuery &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode {
    return Object.hash(
      category,
      searchQuery,
      page,
      pageSize,
    );
  }
}

