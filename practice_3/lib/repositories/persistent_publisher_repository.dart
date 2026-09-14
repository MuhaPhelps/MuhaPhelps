import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/reference_seed_data.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import 'book_repository.dart';
import 'publisher_repository.dart';

class PersistentPublisherRepository
    implements PublisherRepository {
  static const String _key =
      'publishers_v1';

  final SharedPreferences _prefs;
  final BookRepository _bookRepository;

  List<Publisher> _publishers = [];

  int _nextId = 1;

  PersistentPublisherRepository(
    this._prefs,
    this._bookRepository,
  ) {
    _restore();
  }

  void _restore() {
    final raw =
        _prefs.getString(_key);

    if (raw == null) {
      _publishers = [
        ...seedPublisherEntities,
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
          'Некорректный формат издательств',
        );
      }

      _publishers = decoded
          .whereType<Map>()
          .map(
            (item) =>
                Publisher.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .toList();

      _updateNextId();
    } catch (_) {
      _publishers = [
        ...seedPublisherEntities,
      ];

      _updateNextId();

      _persist();
    }
  }

  void _updateNextId() {
    if (_publishers.isEmpty) {
      _nextId = 1;
      return;
    }

    final maxId = _publishers
        .map(
          (publisher) =>
              publisher.id,
        )
        .reduce(
          (a, b) =>
              a > b ? a : b,
        );

    _nextId = maxId + 1;
  }

  Future<void> _persist() async {
    final json = jsonEncode(
      _publishers
          .map(
            (publisher) =>
                publisher.toJson(),
          )
          .toList(),
    );

    await _prefs.setString(
      _key,
      json,
    );
  }

  Future<int> _relatedBookCount(
    int publisherId,
  ) async {
    final result =
        await _bookRepository.find(
      BookQuery(
        publisherId: publisherId,
        includeDeleted: true,
        page: 1,
        size: 50,
      ),
    );

    return result.total;
  }

  Future<void> _assertCanDelete(
    int publisherId,
  ) async {
    final count =
        await _relatedBookCount(
      publisherId,
    );

    if (count > 0) {
      throw PublisherInUseException(
        count,
      );
    }
  }

  @override
  Future<PageResult<Publisher>> find(
    PublisherQuery q,
  ) async {
    await Future.delayed(
      const Duration(
        milliseconds: 200,
      ),
    );

    var rows = _publishers
        .where(
          (publisher) =>
              q.includeDeleted ||
              !publisher.isDeleted,
        )
        .toList();

    if (q.search.trim().isNotEmpty) {
      final needle =
          q.search
              .trim()
              .toLowerCase();

      rows = rows.where(
        (publisher) =>
            publisher.name
                .toLowerCase()
                .contains(needle) ||
            publisher.city
                .toLowerCase()
                .contains(needle),
      ).toList();
    }

    rows.sort(
      (a, b) {
        final result =
            switch (q.sortField) {
          'city' => a.city
              .toLowerCase()
              .compareTo(
                b.city.toLowerCase(),
              ),

          'foundedYear' =>
            (a.foundedYear ?? 0)
                .compareTo(
              b.foundedYear ?? 0,
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
        ? <Publisher>[]
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
  Future<Publisher?> findById(
    int id,
  ) async {
    for (final publisher
        in _publishers) {
      if (publisher.id == id) {
        return publisher;
      }
    }

    return null;
  }

  @override
  Future<Publisher> create(
    Publisher publisher,
  ) async {
    final created = Publisher(
      id: _nextId++,
      name: publisher.name,
      city: publisher.city,
      foundedYear:
          publisher.foundedYear,
      deletedAt:
          publisher.deletedAt,
    );

    _publishers.add(created);

    await _persist();

    return created;
  }

  @override
  Future<Publisher> update(
    Publisher publisher,
  ) async {
    final index =
        _publishers.indexWhere(
      (item) =>
          item.id == publisher.id,
    );

    if (index == -1) {
      throw StateError(
        'Издательство '
        '${publisher.id} не найдено',
      );
    }

    _publishers[index] =
        publisher;

    await _persist();

    return publisher;
  }

  @override
  Future<void> softDelete(
    int id,
  ) async {
    await _assertCanDelete(id);

    final index =
        _publishers.indexWhere(
      (publisher) =>
          publisher.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Издательство $id не найдено',
      );
    }

    _publishers[index] =
        _publishers[index].copyWith(
      deletedAt:
          DateTime.now(),
    );

    await _persist();
  }

  @override
  Future<void> hardDelete(
    int id,
  ) async {
    await _assertCanDelete(id);

    _publishers.removeWhere(
      (publisher) =>
          publisher.id == id,
    );

    await _persist();
  }

  @override
  Future<void> restore(
    int id,
  ) async {
    final index =
        _publishers.indexWhere(
      (publisher) =>
          publisher.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Издательство $id не найдено',
      );
    }

    _publishers[index] =
        _publishers[index].copyWith(
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
      final related =
          await _relatedBookCount(id);

      if (related > 0) {
        continue;
      }

      final index =
          _publishers.indexWhere(
        (publisher) =>
            publisher.id == id &&
            !publisher.isDeleted,
      );

      if (index != -1) {
        _publishers[index] =
            _publishers[index].copyWith(
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