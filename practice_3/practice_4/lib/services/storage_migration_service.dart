import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../models/reader.dart';

class StorageMigrationResult {
  final bool migrated;
  final String? message;

  const StorageMigrationResult({
    required this.migrated,
    this.message,
  });
}

class StorageMigrationService {
  static const String _versionKey =
      'library_schema_version';

  static const int currentVersion = 2;

  final SharedPreferences _prefs;

  final List<String> _resetSections = [];

  StorageMigrationService(
    this._prefs,
  );

  Future<StorageMigrationResult>
      migrate() async {
    final storedVersion =
        _prefs.getInt(_versionKey) ?? 1;

    if (storedVersion >= currentVersion) {
      return const StorageMigrationResult(
        migrated: false,
      );
    }

    await _normalizeList<Book>(
      key: 'books_v1',
      fromJson: Book.fromJson,
      toJson: (value) => value.toJson(),
      sectionName: 'Книги',
    );

    await _normalizeList<Author>(
      key: 'authors_v1',
      fromJson: Author.fromJson,
      toJson: (value) => value.toJson(),
      sectionName: 'Авторы',
    );

    await _normalizeList<Genre>(
      key: 'genres_v1',
      fromJson: Genre.fromJson,
      toJson: (value) => value.toJson(),
      sectionName: 'Жанры',
    );

    await _normalizeList<Publisher>(
      key: 'publishers_v1',
      fromJson: Publisher.fromJson,
      toJson: (value) => value.toJson(),
      sectionName: 'Издательства',
    );

    await _normalizeList<Reader>(
      key: 'readers_v1',
      fromJson: Reader.fromJson,
      toJson: (value) => value.toJson(),
      sectionName: 'Читатели',
    );

    await _prefs.setInt(
      _versionKey,
      currentVersion,
    );

    if (_resetSections.isEmpty) {
      return const StorageMigrationResult(
        migrated: true,
        message:
            'Хранилище данных успешно обновлено '
            'до версии 2. Существующие данные сохранены.',
      );
    }

    return StorageMigrationResult(
      migrated: true,
      message:
          'Хранилище обновлено до версии 2. '
          'Повреждённые данные разделов '
          '${_resetSections.join(', ')} '
          'были безопасно сброшены.',
    );
  }

  Future<void> _normalizeList<T>({
    required String key,
    required T Function(
      Map<String, dynamic> json,
    ) fromJson,
    required Map<String, dynamic> Function(
      T value,
    ) toJson,
    required String sectionName,
  }) async {
    final raw =
        _prefs.getString(key);

    if (raw == null) {
      return;
    }

    try {
      final decoded =
          jsonDecode(raw);

      if (decoded is! List) {
        throw const FormatException(
          'Ожидался список',
        );
      }

      final normalized =
          <Map<String, dynamic>>[];

      for (final item in decoded) {
        if (item is! Map) {
          throw const FormatException(
            'Некорректная запись',
          );
        }

        final model = fromJson(
          Map<String, dynamic>.from(
            item,
          ),
        );

        normalized.add(
          toJson(model),
        );
      }

      await _prefs.setString(
        key,
        jsonEncode(normalized),
      );
    } catch (_) {
      await _prefs.remove(key);

      _resetSections.add(
        sectionName,
      );
    }
  }
}