class LazyLoadPage<T> {
  const LazyLoadPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  final List<T> items;
  final int page;
  final bool hasMore;
}

typedef PageFetcher<T> = Future<List<T>> Function(int page, int pageSize);

class LazyLoader<T> {
  LazyLoader({required this.fetcher, this.pageSize = 20})
    : _items = <T>[],
      _page = 0,
      _hasMore = true,
      _loading = false;

  final PageFetcher<T> fetcher;
  final int pageSize;

  final List<T> _items;
  int _page;
  bool _hasMore;
  bool _loading;

  List<T> get items => List<T>.unmodifiable(_items);

  bool get hasMore => _hasMore;

  bool get isLoading => _loading;

  Future<LazyLoadPage<T>> loadNext() async {
    if (_loading || !_hasMore) {
      return LazyLoadPage<T>(items: items, page: _page, hasMore: _hasMore);
    }

    _loading = true;
    try {
      final nextPage = _page + 1;
      final fetched = await fetcher(nextPage, pageSize);
      _items.addAll(fetched);
      _page = nextPage;
      _hasMore = fetched.length >= pageSize;
      return LazyLoadPage<T>(items: items, page: _page, hasMore: _hasMore);
    } finally {
      _loading = false;
    }
  }

  void reset() {
    _items.clear();
    _page = 0;
    _hasMore = true;
  }
}
