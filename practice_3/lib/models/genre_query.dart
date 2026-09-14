class GenreQuery {
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const GenreQuery({
    this.search = '',
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory GenreQuery.fromQueryParameters(
    Map<String, String> parameters,
  ) {
    final rawPage =
        int.tryParse(parameters['page'] ?? '') ?? 1;

    final page = rawPage < 1 ? 1 : rawPage;

    final rawSize =
        int.tryParse(parameters['size'] ?? '') ?? 10;

    final size = const [10, 25, 50].contains(rawSize)
        ? rawSize
        : 10;

    final sortParts =
        (parameters['sort'] ?? 'name,asc').split(',');

    const allowedFields = {
      'name',
      'description',
    };

    final sortField =
        allowedFields.contains(sortParts.first)
            ? sortParts.first
            : 'name';

    final sortAscending =
        sortParts.length < 2 ||
            sortParts[1] != 'desc';

    return GenreQuery(
      search: parameters['search'] ?? '',
      sortField: sortField,
      sortAscending: sortAscending,
      page: page,
      size: size,
      includeDeleted:
          parameters['deleted'] == '1',
    );
  }

  Map<String, String> toQueryParameters() {
    final result = <String, String>{};

    if (search.trim().isNotEmpty) {
      result['search'] = search.trim();
    }

    if (sortField != 'name' ||
        !sortAscending) {
      result['sort'] =
          '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }

    if (page != 1) {
      result['page'] = '$page';
    }

    if (size != 10) {
      result['size'] = '$size';
    }

    if (includeDeleted) {
      result['deleted'] = '1';
    }

    return result;
  }

  GenreQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return GenreQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending:
          sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted:
          includeDeleted ?? this.includeDeleted,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GenreQuery &&
        other.search == search &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.size == size &&
        other.includeDeleted == includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
        search,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}