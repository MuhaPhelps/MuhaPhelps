import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/reference_seed_data.dart';
import '../models/library_card.dart';
import '../models/page_result.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import 'reader_repository.dart';

class PersistentReaderRepository
    implements ReaderRepository {
  static const String _key =
      'readers_v1';

  final SharedPreferences _prefs;

  List<Reader> _readers = [];

  int _nextId = 1;
  int _nextCardId = 1;

  PersistentReaderRepository(
    this._prefs,
  ) {
    _restore();
  }

  void _restore() {
    final raw =
        _prefs.getString(_key);

    if (raw == null) {
      _readers = [
        ...seedReaders,
      ];

      _updateNextIds();
      _persist();

      return;
    }

    try {
      final decoded =
          jsonDecode(raw);

      if (decoded is! List) {
        throw const FormatException(
          'Некорректный формат читателей',
        );
      }

      _readers = decoded
          .whereType<Map>()
          .map(
            (item) =>
                Reader.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .toList();

      _updateNextIds();
    } catch (_) {
      _readers = [
        ...seedReaders,
      ];

      _updateNextIds();
      _persist();
    }
  }

  void _updateNextIds() {
    if (_readers.isEmpty) {
      _nextId = 1;
      _nextCardId = 1;
      return;
    }

    final maxReaderId = _readers
        .map(
          (reader) => reader.id,
        )
        .reduce(
          (a, b) => a > b ? a : b,
        );

    final maxCardId = _readers
        .map(
          (reader) => reader.card.id,
        )
        .reduce(
          (a, b) => a > b ? a : b,
        );

    _nextId = maxReaderId + 1;
    _nextCardId = maxCardId + 1;
  }

  Future<void> _persist() async {
    final json = jsonEncode(
      _readers
          .map(
            (reader) =>
                reader.toJson(),
          )
          .toList(),
    );

    await _prefs.setString(
      _key,
      json,
    );
  }

  bool _emailExists(
    String email, {
    int? exceptId,
  }) {
    final normalized =
        email.trim().toLowerCase();

    return _readers.any(
      (reader) =>
          reader.id != exceptId &&
          reader.email
                  .trim()
                  .toLowerCase() ==
              normalized,
    );
  }

  @override
  Future<PageResult<Reader>> find(
    ReaderQuery q,
  ) async {
    await Future.delayed(
      const Duration(
        milliseconds: 200,
      ),
    );

    var rows = _readers
        .where(
          (reader) =>
              q.includeDeleted ||
              !reader.isDeleted,
        )
        .toList();

    if (q.search.trim().isNotEmpty) {
      final needle =
          q.search
              .trim()
              .toLowerCase();

      rows = rows.where(
        (reader) =>
            reader.fullName
                .toLowerCase()
                .contains(needle) ||
            reader.email
                .toLowerCase()
                .contains(needle) ||
            reader.phone
                .toLowerCase()
                .contains(needle) ||
            reader.card.number
                .toLowerCase()
                .contains(needle),
      ).toList();
    }

    rows.sort(
      (a, b) {
        final result =
            switch (q.sortField) {
          'email' => a.email
              .toLowerCase()
              .compareTo(
                b.email.toLowerCase(),
              ),

          'phone' => a.phone
              .toLowerCase()
              .compareTo(
                b.phone.toLowerCase(),
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
        ? <Reader>[]
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
  Future<Reader?> findById(
    int id,
  ) async {
    for (final reader in _readers) {
      if (reader.id == id) {
        return reader;
      }
    }

    return null;
  }

  @override
  Future<Reader> create(
    Reader reader,
  ) async {
    if (_emailExists(
      reader.email,
    )) {
      throw ReaderEmailExistsException(
        reader.email,
      );
    }

    final createdCard =
        LibraryCard(
      id: _nextCardId++,
      number: reader.card.number,
      issuedAt:
          reader.card.issuedAt,
      expiresAt:
          reader.card.expiresAt,
    );

    final created = Reader(
      id: _nextId++,
      fullName:
          reader.fullName,
      email:
          reader.email.trim(),
      phone:
          reader.phone,
      card:
          createdCard,
      deletedAt:
          reader.deletedAt,
    );

    _readers.add(created);

    await _persist();

    return created;
  }

  @override
  Future<Reader> update(
    Reader reader,
  ) async {
    final index =
        _readers.indexWhere(
      (item) =>
          item.id == reader.id,
    );

    if (index == -1) {
      throw StateError(
        'Читатель '
        '${reader.id} не найден',
      );
    }

    if (_emailExists(
      reader.email,
      exceptId: reader.id,
    )) {
      throw ReaderEmailExistsException(
        reader.email,
      );
    }

    _readers[index] =
        reader.copyWith(
      email:
          reader.email.trim(),
    );

    await _persist();

    return _readers[index];
  }

  @override
  Future<void> softDelete(
    int id,
  ) async {
    final index =
        _readers.indexWhere(
      (reader) =>
          reader.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Читатель $id не найден',
      );
    }

    _readers[index] =
        _readers[index].copyWith(
      deletedAt:
          DateTime.now(),
    );

    await _persist();
  }

  @override
  Future<void> hardDelete(
    int id,
  ) async {
    _readers.removeWhere(
      (reader) =>
          reader.id == id,
    );

    await _persist();
  }

  @override
  Future<void> restore(
    int id,
  ) async {
    final index =
        _readers.indexWhere(
      (reader) =>
          reader.id == id,
    );

    if (index == -1) {
      throw StateError(
        'Читатель $id не найден',
      );
    }

    _readers[index] =
        _readers[index].copyWith(
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
          _readers.indexWhere(
        (reader) =>
            reader.id == id &&
            !reader.isDeleted,
      );

      if (index != -1) {
        _readers[index] =
            _readers[index].copyWith(
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