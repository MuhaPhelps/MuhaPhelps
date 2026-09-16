import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import '../repositories/book_repository.dart';

enum LoadStatus {
  idle,
  loading,
  success,
  error,
}

class BookListNotifier
    extends ChangeNotifier {
  final BookRepository _repository;

  BookListNotifier(
    this._repository,
  );

  BookQuery _query =
      const BookQuery();

  PageResult<Book> _result =
      PageResult.empty();

  LoadStatus _status =
      LoadStatus.idle;

  String? _error;

  final Set<int> _selected = {};

  int _loadRequestId = 0;

  BookQuery get query =>
      _query;

  PageResult<Book> get result =>
      _result;

  LoadStatus get status =>
      _status;

  String? get error =>
      _error;

  Set<int> get selected =>
      Set.unmodifiable(
        _selected,
      );

  bool get hasSelection =>
      _selected.isNotEmpty;

  int get selectedCount =>
      _selected.length;

  Future<void> load() async {
    final requestId =
        ++_loadRequestId;

    _status =
        LoadStatus.loading;

    _error =
        null;

    notifyListeners();

    try {
      final PageResult<Book> result;

      if (_repository
          is CancellableBookRepository) {
        final cancellableRepository =
            _repository
                as CancellableBookRepository;

        result =
            await cancellableRepository
                .findCancellable(
          _query,
        );
      } else {
        result =
            await _repository.find(
          _query,
        );
      }

      if (requestId !=
          _loadRequestId) {
        return;
      }

      _result =
          result;

      _status =
          LoadStatus.success;
    } on BookSearchCancelledException {
      // Предыдущий запрос был отменён,
      // потому что уже отправлен новый.
      // Это не ошибка для пользователя.
      return;
    } catch (e) {
      if (requestId !=
          _loadRequestId) {
        return;
      }

      _error =
          'Не удалось загрузить список: $e';

      _status =
          LoadStatus.error;
    }

    if (requestId ==
        _loadRequestId) {
      notifyListeners();
    }
  }

  Future<void> applyQuery(
    BookQuery next,
  ) async {
    _query =
        next;

    _selected.clear();

    await load();
  }

  Future<Book?> findById(
    int id,
  ) {
    return _repository.findById(
      id,
    );
  }

  Future<Book> create(
    Book book,
  ) async {
    final result =
        await _repository.create(
      book,
    );

    await load();

    return result;
  }

  Future<Book> update(
    Book book,
  ) async {
    final result =
        await _repository.update(
      book,
    );

    await load();

    return result;
  }

  void toggleSelection(
    int id,
  ) {
    if (_selected.contains(
      id,
    )) {
      _selected.remove(
        id,
      );
    } else {
      _selected.add(
        id,
      );
    }

    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();

    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(
      _selected.toList(),
    );

    _selected.clear();

    await load();
  }

  Future<void> softDelete(
    int id,
  ) async {
    await _repository.softDelete(
      id,
    );

    _selected.remove(
      id,
    );

    await load();
  }

  Future<void> hardDelete(
    int id,
  ) async {
    await _repository.hardDelete(
      id,
    );

    _selected.remove(
      id,
    );

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
}