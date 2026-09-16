import 'package:flutter/foundation.dart';

import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import '../repositories/genre_repository.dart';
import 'book_list_notifier.dart';

class GenreListNotifier
    extends ChangeNotifier {
  final GenreRepository _repository;

  GenreListNotifier(
    this._repository,
  );

  GenreQuery _query =
      const GenreQuery();

  PageResult<Genre> _result =
      PageResult.empty();

  LoadStatus _status =
      LoadStatus.idle;

  String? _error;

  final Set<int> _selected = {};

  GenreQuery get query => _query;

  PageResult<Genre> get result =>
      _result;

  LoadStatus get status => _status;

  String? get error => _error;

  Set<int> get selected =>
      Set.unmodifiable(_selected);

  bool get hasSelection =>
      _selected.isNotEmpty;

  int get selectedCount =>
      _selected.length;

  Future<void> load() async {
    _status =
        LoadStatus.loading;

    _error = null;

    notifyListeners();

    try {
      _result =
          await _repository.find(
        _query,
      );

      _status =
          LoadStatus.success;
    } catch (e) {
      _error =
          'Не удалось загрузить жанры: $e';

      _status =
          LoadStatus.error;
    }

    notifyListeners();
  }

  Future<void> applyQuery(
    GenreQuery next,
  ) async {
    _query = next;

    _selected.clear();

    await load();
  }

  Future<Genre?> findById(
    int id,
  ) {
    return _repository.findById(id);
  }

  Future<Genre> create(
    Genre genre,
  ) async {
    final result =
        await _repository.create(
      genre,
    );

    await load();

    return result;
  }

  Future<Genre> update(
    Genre genre,
  ) async {
    final result =
        await _repository.update(
      genre,
    );

    await load();

    return result;
  }

  void toggleSelection(
    int id,
  ) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }

    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();

    notifyListeners();
  }

  Future<void> softDelete(
    int id,
  ) async {
    await _repository.softDelete(
      id,
    );

    _selected.remove(id);

    await load();
  }

  Future<void> hardDelete(
    int id,
  ) async {
    await _repository.hardDelete(
      id,
    );

    _selected.remove(id);

    await load();
  }

  Future<void> restore(
    int id,
  ) async {
    await _repository.restore(
      id,
    );

    await load();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(
      _selected.toList(),
    );

    _selected.clear();

    await load();
  }
}