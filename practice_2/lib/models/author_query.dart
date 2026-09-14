class AuthorQuery {
  final String search;

  final String sortField;
  final bool sortAscending;

  final int page;
  final int size;

  final bool includeDeleted;

  const AuthorQuery({
    this.search = '',
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory AuthorQuery.fromQueryParameters(
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
      parameters['sort'] ?? 'lastName,asc'
    ).split(',');

    const allowedSortFields = {
      'lastName',
      'firstName',
      'country',
    };

    final sortField = allowedSortFields.contains(
      sortParts.first,
    )
        ? sortParts.first
        : 'lastName';

    final sortAscending =
        sortParts.length < 2 || sortParts[1] != 'desc';

    return AuthorQuery(
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
    final parameters = <String, String>{};

    if (search.trim().isNotEmpty) {
      parameters['search'] = search.trim();
    }

    if (sortField != 'lastName' || !sortAscending) {
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

  AuthorQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AuthorQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending:
          sortAscending ?? this.sortAscending,

      // Изменение условий возвращает
      // пользователя на первую страницу.
      page: page ?? 1,

      size: size ?? this.size,
      includeDeleted:
          includeDeleted ?? this.includeDeleted,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthorQuery &&
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