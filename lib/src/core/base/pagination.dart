class PaginationQuery {
  const PaginationQuery({required this.page, required this.pageSize});

  final int page;
  final int pageSize;
}

class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;

  int get totalPages {
    if (pageSize <= 0) {
      return 0;
    }
    return (totalCount / pageSize).ceil();
  }
}
