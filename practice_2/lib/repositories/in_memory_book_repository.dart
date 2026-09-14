import '../data/seed_data.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class InMemoryBookRepository implements BookRepository {
  final List<Book> _books = [...seedBooks];

  int _nextId = seedBooks.length + 1;

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    // Демонстрационный сценарий для проверки
    // состояния error в интерфейсе.
    //
    // Введите !error в строку поиска.
    if (q.search.trim().toLowerCase() == '!error') {
      throw Exception(
        'Демонстрационная ошибка загрузки данных',
      );
    }

    var rows = _books
        .where(
          (book) =>
              q.includeDeleted || !book.isDeleted,
        )
        .toList();

    if (q.search.trim().isNotEmpty) {
      final needle =
          q.search.trim().toLowerCase();

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
            book.genreIds.contains(q.genreId),
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
            book.year >= q.yearFrom!,
      ).toList();
    }

    if (q.yearTo != null) {
      rows = rows.where(
        (book) =>
            book.year <= q.yearTo!,
      ).toList();
    }

    rows.sort(
      (a, b) {
        final result = switch (q.sortField) {
          'year' =>
            a.year.compareTo(b.year),

          'pages' =>
            a.pages.compareTo(b.pages),

          _ => a.title
              .toLowerCase()
              .compareTo(
                b.title.toLowerCase(),
              ),
        };

        return q.sortAscending
            ? result
            : -result;
      },
    );

    final total = rows.length;

    final from =
        (q.page - 1) * q.size;

    final to =
        (from + q.size) > total
            ? total
            : from + q.size;

    final items = from >= total
        ? <Book>[]
        : rows.sublist(from, to);

    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Book?> findById(int id) async {
    for (final book in _books) {
      if (book.id == id) {
        return book;
      }
    }

    return null;
  }

  @override
  Future<Book> create(Book book) async {
    final createdBook = Book(
      id: _nextId++,
      title: book.title,
      isbn: book.isbn,
      year: book.year,
      pages: book.pages,
      publisherId: book.publisherId,
      authorIds: book.authorIds,
      genreIds: book.genreIds,
      copiesTotal: book.copiesTotal,
      copiesAvailable:
          book.copiesAvailable,
      deletedAt: book.deletedAt,
    );

    _books.add(createdBook);

    return createdBook;
  }

  @override
  Future<Book> update(Book book) async {
    final index = _books.indexWhere(
      (item) => item.id == book.id,
    );

    if (index == -1) {
      throw StateError(
        'Книга ${book.id} не найдена',
      );
    }

    _books[index] = book;

    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _books.indexWhere(
      (book) => book.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Книга $id не найдена',
      );
    }

    _books[index] = _books[index].copyWith(
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    _books.removeWhere(
      (book) => book.id == id,
    );
  }

  @override
  Future<void> restore(int id) async {
    final index = _books.indexWhere(
      (book) => book.id == id,
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
  }

  @override
  Future<int> deleteMany(
    List<int> ids,
  ) async {
    var count = 0;

    for (final id in ids) {
      final index = _books.indexWhere(
        (book) =>
            book.id == id &&
            !book.isDeleted,
      );

      if (index != -1) {
        _books[index] =
            _books[index].copyWith(
          deletedAt: DateTime.now(),
        );

        count++;
      }
    }

    return count;
  }
}