import 'package:flutter/foundation.dart';

import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../repositories/publisher_repository.dart';
import 'book_list_notifier.dart';

class PublisherListNotifier
    extends ChangeNotifier {
  final PublisherRepository _repository;

  PublisherListNotifier(
    this._repository,
  );

  PublisherQuery _query =
      const PublisherQuery();

  PageResult<Publisher> _result =
      PageResult.empty();

  LoadStatus _status =
      LoadStatus.idle;

  String? _error;

  final Set<int> _selected = {};

  PublisherQuery get query =>
      _query;

  PageResult<Publisher> get result =>
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
          'Не удалось загрузить '
          'издательства: $e';

      _status =
          LoadStatus.error;
    }

    notifyListeners();
  }

  Future<void> applyQuery(
    PublisherQuery next,
  ) async {
    _query = next;

    _selected.clear();

    await load();
  }

  Future<Publisher?> findById(
    int id,
  ) {
    return _repository.findById(id);
  }

  Future<Publisher> create(
    Publisher publisher,
  ) async {
    final result =
        await _repository.create(
      publisher,
    );

    await load();

    return result;
  }

  Future<Publisher> update(
    Publisher publisher,
  ) async {
    final result =
        await _repository.update(
      publisher,
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