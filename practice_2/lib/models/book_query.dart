class BookQuery {
  final String search;
  final int? genreId;
  final int? publisherId;
  final int? yearFrom;
  final int? yearTo;

  final String sortField;
  final bool sortAscending;

  final int page;
  final int size;

  final bool includeDeleted;

  const BookQuery({
    this.search = '',
    this.genreId,
    this.publisherId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory BookQuery.fromQueryParameters(
    Map<String, String> parameters,
  ) {
    final rawPage = int.tryParse(
          parameters['page'] ?? '',
        ) ??
        1;

    final page = rawPage < 1 ? 1 : rawPage;

    final rawSize = int.tryParse(
          parameters['size'] ?? '',
        ) ??
        10;

    final size = const [10, 25, 50].contains(rawSize)
        ? rawSize
        : 10;

    final sortParts = (
      parameters['sort'] ?? 'title,asc'
    ).split(',');

    const allowedSortFields = {
      'title',
      'year',
      'pages',
    };

    final sortField = allowedSortFields.contains(
      sortParts.first,
    )
        ? sortParts.first
        : 'title';

    final sortAscending =
        sortParts.length < 2 || sortParts[1] != 'desc';

    return BookQuery(
      search: parameters['search'] ?? '',
      genreId: int.tryParse(
        parameters['genreId'] ?? '',
      ),
      publisherId: int.tryParse(
        parameters['publisherId'] ?? '',
      ),
      yearFrom: int.tryParse(
        parameters['yearFrom'] ?? '',
      ),
      yearTo: int.tryParse(
        parameters['yearTo'] ?? '',
      ),
      sortField: sortField,
      sortAscending: sortAscending,
      page: page,
      size: size,
      includeDeleted:
          parameters['deleted'] == '1',
    );
  }

  Map<String, String> toQueryParameters() {
    final parameters = <String, String>{};

    if (search.trim().isNotEmpty) {
      parameters['search'] = search.trim();
    }

    if (genreId != null) {
      parameters['genreId'] = '$genreId';
    }

    if (publisherId != null) {
      parameters['publisherId'] = '$publisherId';
    }

    if (yearFrom != null) {
      parameters['yearFrom'] = '$yearFrom';
    }

    if (yearTo != null) {
      parameters['yearTo'] = '$yearTo';
    }

    if (sortField != 'title' || !sortAscending) {
      parameters['sort'] =
          '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }

    if (page != 1) {
      parameters['page'] = '$page';
    }

    if (size != 10) {
      parameters['size'] = '$size';
    }

    if (includeDeleted) {
      parameters['deleted'] = '1';
    }

    return parameters;
  }

  BookQuery copyWith({
    String? search,
    Object? genreId = _unset,
    Object? publisherId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BookQuery(
      search: search ?? this.search,
      genreId: genreId == _unset
          ? this.genreId
          : genreId as int?,
      publisherId: publisherId == _unset
          ? this.publisherId
          : publisherId as int?,
      yearFrom: yearFrom == _unset
          ? this.yearFrom
          : yearFrom as int?,
      yearTo: yearTo == _unset
          ? this.yearTo
          : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending:
          sortAscending ?? this.sortAscending,

      // Если page явно не передана,
      // изменение условий возвращает нас на страницу 1.
      page: page ?? 1,

      size: size ?? this.size,
      includeDeleted:
          includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  @override
  bool operator ==(Object other) {
    return other is BookQuery &&
        other.search == search &&
        other.genreId == genreId &&
        other.publisherId == publisherId &&
        other.yearFrom == yearFrom &&
        other.yearTo == yearTo &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.size == size &&
        other.includeDeleted == includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
        search,
        genreId,
        publisherId,
        yearFrom,
        yearTo,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}