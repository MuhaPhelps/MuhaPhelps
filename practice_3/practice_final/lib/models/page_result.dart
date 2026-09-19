class PageResult<T> {
  final int page;
  final int perPage;
  final int totalPages;
  final int totalItems;
  final List<T> items;

  const PageResult({
    required this.page,
    required this.perPage,
    required this.totalPages,
    required this.totalItems,
    required this.items,
  });
}
