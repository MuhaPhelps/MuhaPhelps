import '../data/seed_data.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

class InMemoryAuthorRepository
    implements AuthorRepository {
  final List<Author> _authors = [...seedAuthors];

  int _nextId = seedAuthors.length + 1;

  @override
  Future<PageResult<Author>> find(
    AuthorQuery q,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    var rows = _authors
        .where(
          (author) =>
              q.includeDeleted ||
              !author.isDeleted,
        )
        .toList();

    if (q.search.trim().isNotEmpty) {
      final needle =
          q.search.trim().toLowerCase();

      rows = rows.where(
        (author) =>
            author.fullName
                .toLowerCase()
                .contains(needle) ||
            author.country
                .toLowerCase()
                .contains(needle),
      ).toList();
    }

    rows.sort(
      (a, b) {
        final result = switch (q.sortField) {
          'birthYear' => (a.birthYear ?? 0)
              .compareTo(
                b.birthYear ?? 0,
              ),

          'country' => a.country
              .toLowerCase()
              .compareTo(
                b.country.toLowerCase(),
              ),

          _ => a.fullName
              .toLowerCase()
              .compareTo(
                b.fullName.toLowerCase(),
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
        ? <Author>[]
        : rows.sublist(from, to);

    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Author?> findById(
    int id,
  ) async {
    for (final author in _authors) {
      if (author.id == id) {
        return author;
      }
    }

    return null;
  }

  @override
  Future<Author> create(
    Author author,
  ) async {
    final createdAuthor = Author(
      id: _nextId++,
      fullName: author.fullName,
      birthYear: author.birthYear,
      country: author.country,
      deletedAt: author.deletedAt,
    );

    _authors.add(createdAuthor);

    return createdAuthor;
  }

  @override
  Future<Author> update(
    Author author,
  ) async {
    final index = _authors.indexWhere(
      (item) => item.id == author.id,
    );

    if (index == -1) {
      throw StateError(
        'Автор ${author.id} не найден',
      );
    }

    _authors[index] = author;

    return author;
  }

  @override
  Future<void> softDelete(
    int id,
  ) async {
    final index = _authors.indexWhere(
      (author) => author.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Автор $id не найден',
      );
    }

    _authors[index] =
        _authors[index].copyWith(
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<void> hardDelete(
    int id,
  ) async {
    _authors.removeWhere(
      (author) => author.id == id,
    );
  }

  @override
  Future<void> restore(
    int id,
  ) async {
    final index = _authors.indexWhere(
      (author) => author.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Автор $id не найден',
      );
    }

    _authors[index] =
        _authors[index].copyWith(
      clearDeletedAt: true,
    );
  }

  @override
  Future<int> deleteMany(
    List<int> ids,
  ) async {
    var count = 0;

    for (final id in ids) {
      final index = _authors.indexWhere(
        (author) =>
            author.id == id &&
            !author.isDeleted,
      );

      if (index != -1) {
        _authors[index] =
            _authors[index].copyWith(
          deletedAt: DateTime.now(),
        );

        count++;
      }
    }

    return count;
  }
}