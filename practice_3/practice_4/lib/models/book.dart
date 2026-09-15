class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;

  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;

  final int copiesTotal;
  final int copiesAvailable;

  final DateTime? deletedAt;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
  });

  bool get isDeleted =>
      deletedAt != null;

  Book copyWith({
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId:
          publisherId ??
              this.publisherId,
      authorIds:
          authorIds ??
              [...this.authorIds],
      genreIds:
          genreIds ??
              [...this.genreIds],
      copiesTotal:
          copiesTotal ??
              this.copiesTotal,
      copiesAvailable:
          copiesAvailable ??
              this.copiesAvailable,
      deletedAt:
          clearDeletedAt
              ? null
              : deletedAt ??
                  this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isbn': isbn,
      'year': year,
      'pages': pages,
      'publisherId': publisherId,
      'authorIds': authorIds,
      'genreIds': genreIds,
      'copiesTotal': copiesTotal,
      'copiesAvailable':
          copiesAvailable,
      'deletedAt':
          deletedAt
              ?.toIso8601String(),
    };
  }

  factory Book.fromJson(
    Map<String, dynamic> json,
  ) {
    return Book(
      id: _toInt(
        json['id'],
      ),
      title:
          json['title']
                  ?.toString() ??
              '',
      isbn:
          json['isbn']
                  ?.toString() ??
              '',
      year: _toInt(
        json['year'],
      ),
      pages: _toInt(
        json['pages'],
      ),

      // Старый формат:
      // "publisherId": 1
      //
      // Формат API:
      // "publisher": {
      //   "id": 1,
      //   "name": "..."
      // }
      publisherId:
          _publisherIdFromJson(
        json,
      ),

      // Старый формат:
      // "authorIds": [1, 2]
      //
      // Формат API:
      // "authors": [
      //   {"id": 1, ...},
      //   {"id": 2, ...}
      // ]
      authorIds:
          _relationIdsFromJson(
        directValue:
            json['authorIds'],
        expandedValue:
            json['authors'],
      ),

      // Аналогично авторам.
      genreIds:
          _relationIdsFromJson(
        directValue:
            json['genreIds'],
        expandedValue:
            json['genres'],
      ),

      copiesTotal:
          _toInt(
        json['copiesTotal'],
      ),

      copiesAvailable:
          _toInt(
        json['copiesAvailable'],
      ),

      deletedAt:
          _toDateTime(
        json['deletedAt'],
      ),
    );
  }

  static int _publisherIdFromJson(
    Map<String, dynamic> json,
  ) {
    final direct =
        json['publisherId'];

    if (direct != null) {
      return _toInt(
        direct,
      );
    }

    final publisher =
        json['publisher'];

    if (publisher is Map) {
      return _toInt(
        publisher['id'],
      );
    }

    return 0;
  }

  static List<int>
      _relationIdsFromJson({
    required dynamic directValue,
    required dynamic expandedValue,
  }) {
    // Формат из ПР3:
    // [1, 2, 3]
    if (directValue is List) {
      return directValue
          .map(_toInt)
          .where(
            (id) => id > 0,
          )
          .toList();
    }

    // Формат REST API:
    // [
    //   {"id": 1, ...},
    //   {"id": 2, ...}
    // ]
    if (expandedValue is List) {
      final result =
          <int>[];

      for (final item
          in expandedValue) {
        if (item is Map) {
          final id =
              _toInt(
            item['id'],
          );

          if (id > 0) {
            result.add(id);
          }
        }
      }

      return result;
    }

    return <int>[];
  }

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    final text =
        value.toString();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      text,
    );
  }
}