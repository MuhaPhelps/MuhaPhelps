import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/reference_seed_data.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import 'genre_repository.dart';

class PersistentGenreRepository
    implements GenreRepository {
  static const String _key =
      'genres_v1';

  final SharedPreferences _prefs;

  List<Genre> _genres = [];

  int _nextId = 1;

  PersistentGenreRepository(
    this._prefs,
  ) {
    _restore();
  }

  void _restore() {
    final raw =
        _prefs.getString(_key);

    if (raw == null) {
      _genres = [
        ...seedGenreEntities,
      ];

      _updateNextId();

      _persist();

      return;
    }

    try {
      final decoded =
          jsonDecode(raw);

      if (decoded is! List) {
        throw const FormatException(
          'Некорректный формат жанров',
        );
      }

      _genres = decoded
          .whereType<Map>()
          .map(
            (item) => Genre.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .toList();

      _updateNextId();
    } catch (_) {
      _genres = [
        ...seedGenreEntities,
      ];

      _updateNextId();

      _persist();
    }
  }

  void _updateNextId() {
    if (_genres.isEmpty) {
      _nextId = 1;
      return;
    }

    final maxId = _genres
        .map(
          (genre) => genre.id,
        )
        .reduce(
          (a, b) => a > b ? a : b,
        );

    _nextId = maxId + 1;
  }

  Future<void> _persist() async {
    final json = jsonEncode(
      _genres
          .map(
            (genre) =>
                genre.toJson(),
          )
          .toList(),
    );

    await _prefs.setString(
      _key,
      json,
    );
  }

  @override
  Future<PageResult<Genre>> find(
    GenreQuery q,
  ) async {
    await Future.delayed(
      const Duration(
        milliseconds: 200,
      ),
    );

    var rows = _genres
        .where(
          (genre) =>
              q.includeDeleted ||
              !genre.isDeleted,
        )
        .toList();

    if (q.search.trim().isNotEmpty) {
      final needle =
          q.search
              .trim()
              .toLowerCase();

      rows = rows.where(
        (genre) =>
            genre.name
                .toLowerCase()
                .contains(needle) ||
            genre.description
                .toLowerCase()
                .contains(needle),
      ).toList();
    }

    rows.sort(
      (a, b) {
        final result =
            switch (q.sortField) {
          'description' =>
            a.description
                .toLowerCase()
                .compareTo(
                  b.description
                      .toLowerCase(),
                ),
          _ => a.name
              .toLowerCase()
              .compareTo(
                b.name.toLowerCase(),
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
        ? <Genre>[]
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
  Future<Genre?> findById(
    int id,
  ) async {
    for (final genre in _genres) {
      if (genre.id == id) {
        return genre;
      }
    }

    return null;
  }

  @override
  Future<Genre> create(
    Genre genre,
  ) async {
    final created = Genre(
      id: _nextId++,
      name: genre.name,
      description:
          genre.description,
      deletedAt:
          genre.deletedAt,
    );

    _genres.add(created);

    await _persist();

    return created;
  }

  @override
  Future<Genre> update(
    Genre genre,
  ) async {
    final index =
        _genres.indexWhere(
      (item) =>
          item.id == genre.id,
    );

    if (index == -1) {
      throw StateError(
        'Жанр ${genre.id} не найден',
      );
    }

    _genres[index] = genre;

    await _persist();

    return genre;
  }

  @override
  Future<void> softDelete(
    int id,
  ) async {
    final index =
        _genres.indexWhere(
      (genre) =>
          genre.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Жанр $id не найден',
      );
    }

    _genres[index] =
        _genres[index].copyWith(
      deletedAt:
          DateTime.now(),
    );

    await _persist();
  }

  @override
  Future<void> hardDelete(
    int id,
  ) async {
    _genres.removeWhere(
      (genre) => genre.id == id,
    );

    await _persist();
  }

  @override
  Future<void> restore(
    int id,
  ) async {
    final index =
        _genres.indexWhere(
      (genre) =>
          genre.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Жанр $id не найден',
      );
    }

    _genres[index] =
        _genres[index].copyWith(
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
          _genres.indexWhere(
        (genre) =>
            genre.id == id &&
            !genre.isDeleted,
      );

      if (index != -1) {
        _genres[index] =
            _genres[index].copyWith(
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