import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class PersistentBookRepository
    implements BookRepository {
  static const String _key =
      'books_v1';

  final SharedPreferences _prefs;

  List<Book> _books = [];

  int _nextId = 1;

  PersistentBookRepository(
    this._prefs,
  ) {
    _restore();
  }

  void _restore() {
    final raw =
        _prefs.getString(_key);

    if (raw == null) {
      _books = [...seedBooks];

      _updateNextId();
      _persist();

      return;
    }

    try {
      final decoded =
          jsonDecode(raw);

      if (decoded is! List) {
        throw const FormatException(
          'Некорректный формат списка книг',
        );
      }

      _books = decoded
          .whereType<Map>()
          .map(
            (item) => Book.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .toList();

      _updateNextId();
    } catch (_) {
      _books = [...seedBooks];

      _updateNextId();
      _persist();
    }
  }

  void _updateNextId() {
    if (_books.isEmpty) {
      _nextId = 1;
      return;
    }

    final maxId = _books
        .map(
          (book) => book.id,
        )
        .reduce(
          (a, b) => a > b ? a : b,
        );

    _nextId = maxId + 1;
  }

  Future<void> _persist() async {
    final json = jsonEncode(
      _books
          .map(
            (book) => book.toJson(),
          )
          .toList(),
    );

    await _prefs.setString(
      _key,
      json,
    );
  }

  bool _isbnExists(
    String isbn, {
    int? exceptId,
  }) {
    final normalized =
        isbn.trim().toLowerCase();

    return _books.any(
      (book) =>
          book.id != exceptId &&
          book.isbn
                  .trim()
                  .toLowerCase() ==
              normalized,
    );
  }

  @override
  Future<PageResult<Book>> find(
    BookQuery q,
  ) async {
    await Future.delayed(
      const Duration(
        milliseconds: 250,
      ),
    );

    if (q.search
            .trim()
            .toLowerCase() ==
        '!error') {
      throw Exception(
        'Демонстрационная ошибка загрузки данных',
      );
    }

    var rows = _books
        .where(
          (book) =>
              q.includeDeleted ||
              !book.isDeleted,
        )
        .toList();

    if (q.search.trim().isNotEmpty) {
      final needle =
          q.search
              .trim()
              .toLowerCase();

      rows = rows.where(
        (book) =>
            book.title
                .toLowerCase()
                .contains(needle) ||
            book.isbn
                .toLowerCase()
                .contains(needle),
      ).toList();
    }

    if (q.genreId != null) {
      rows = rows.where(
        (book) =>
            book.genreIds.contains(
          q.genreId,
        ),
      ).toList();
    }

    if (q.publisherId != null) {
      rows = rows.where(
        (book) =>
            book.publisherId ==
            q.publisherId,
      ).toList();
    }

    if (q.yearFrom != null) {
      rows = rows.where(
        (book) =>
            book.year >=
            q.yearFrom!,
      ).toList();
    }

    if (q.yearTo != null) {
      rows = rows.where(
        (book) =>
            book.year <=
            q.yearTo!,
      ).toList();
    }

    rows.sort(
      (a, b) {
        final result =
            switch (q.sortField) {
          'year' =>
            a.year.compareTo(
              b.year,
            ),

          'pages' =>
            a.pages.compareTo(
              b.pages,
            ),

          _ => a.title
              .toLowerCase()
              .compareTo(
                b.title
                    .toLowerCase(),
              ),
        };

        return q.sortAscending
            ? result
            : -result;
      },
    );

    final total =
        rows.length;

    final from =
        (q.page - 1) * q.size;

    final to =
        (from + q.size) > total
            ? total
            : from + q.size;

    final items =
        from >= total
            ? <Book>[]
            : rows.sublist(
                from,
                to,
              );

    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Book?> findById(
    int id,
  ) async {
    for (final book in _books) {
      if (book.id == id) {
        return book;
      }
    }

    return null;
  }

  @override
  Future<Book> create(
    Book book,
  ) async {
    if (_isbnExists(
      book.isbn,
    )) {
      throw BookIsbnExistsException(
        book.isbn,
      );
    }

    final created = Book(
      id: _nextId++,
      title:
          book.title.trim(),
      isbn:
          book.isbn.trim(),
      year:
          book.year,
      pages:
          book.pages,
      publisherId:
          book.publisherId,
      authorIds: [
        ...book.authorIds,
      ],
      genreIds: [
        ...book.genreIds,
      ],
      copiesTotal:
          book.copiesTotal,
      copiesAvailable:
          book.copiesAvailable,
      deletedAt:
          book.deletedAt,
    );

    _books.add(
      created,
    );

    await _persist();

    return created;
  }

  @override
  Future<Book> update(
    Book book,
  ) async {
    final index =
        _books.indexWhere(
      (item) =>
          item.id == book.id,
    );

    if (index == -1) {
      throw StateError(
        'Книга ${book.id} не найдена',
      );
    }

    if (_isbnExists(
      book.isbn,
      exceptId: book.id,
    )) {
      throw BookIsbnExistsException(
        book.isbn,
      );
    }

    final updated = Book(
      id: book.id,
      title:
          book.title.trim(),
      isbn:
          book.isbn.trim(),
      year:
          book.year,
      pages:
          book.pages,
      publisherId:
          book.publisherId,
      authorIds: [
        ...book.authorIds,
      ],
      genreIds: [
        ...book.genreIds,
      ],
      copiesTotal:
          book.copiesTotal,
      copiesAvailable:
          book.copiesAvailable,
      deletedAt:
          book.deletedAt,
    );

    _books[index] =
        updated;

    await _persist();

    return updated;
  }

  @override
  Future<void> softDelete(
    int id,
  ) async {
    final index =
        _books.indexWhere(
      (book) =>
          book.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Книга $id не найдена',
      );
    }

    _books[index] =
        _books[index].copyWith(
      deletedAt:
          DateTime.now(),
    );

    await _persist();
  }

  @override
  Future<void> hardDelete(
    int id,
  ) async {
    _books.removeWhere(
      (book) =>
          book.id == id,
    );

    await _persist();
  }

  @override
  Future<void> restore(
    int id,
  ) async {
    final index =
        _books.indexWhere(
      (book) =>
          book.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Книга $id не найдена',
      );
    }

    _books[index] =
        _books[index].copyWith(
      clearDeletedAt: true,
    );

    await _persist();
  }

  @override
  Future<int> deleteMany(
    List<int> ids,
  ) async {
    var count = 0;

    for (final id in ids) {
      final index =
          _books.indexWhere(
        (book) =>
            book.id == id &&
            !book.isDeleted,
      );

      if (index != -1) {
        _books[index] =
            _books[index].copyWith(
          deletedAt:
              DateTime.now(),
        );

        count++;
      }
    }

    await _persist();

    return count;
  }
}