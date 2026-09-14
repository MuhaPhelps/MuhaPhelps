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

  bool get isDeleted => deletedAt != null;

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
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? this.authorIds,
      genreIds: genreIds ?? this.genreIds,
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable:
          copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt
          ? null
          : (deletedAt ?? this.deletedAt),
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
      'copiesAvailable': copiesAvailable,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Book.fromJson(
    Map<String, dynamic> json,
  ) {
    return Book(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      isbn: json['isbn']?.toString() ?? '',
      year: _toInt(json['year']),
      pages: _toInt(json['pages']),
      publisherId:
          _toInt(json['publisherId']),
      authorIds:
          _toIntList(json['authorIds']),
      genreIds:
          _toIntList(json['genreIds']),
      copiesTotal:
          _toInt(json['copiesTotal']),
      copiesAvailable:
          _toInt(json['copiesAvailable']),
      deletedAt: _toDateTime(
        json['deletedAt'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static List<int> _toIntList(
    dynamic value,
  ) {
    if (value is! List) {
      return <int>[];
    }

    return value.map(_toInt).toList();
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}