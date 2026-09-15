import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../state/book_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final _searchController = TextEditingController();
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();

  Timer? _searchDebounce;

  Uri? _lastUri;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final uri = GoRouterState.of(context).uri;

    if (_lastUri == uri) {
      return;
    }

    _lastUri = uri;

    final query = BookQuery.fromQueryParameters(
      uri.queryParameters,
    );

    _searchController.text = query.search;
    _yearFromController.text =
        query.yearFrom?.toString() ?? '';
    _yearToController.text =
        query.yearTo?.toString() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final notifier = context.read<BookListNotifier>();

      if (notifier.query != query ||
          notifier.status == LoadStatus.idle) {
        notifier.applyQuery(query);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();

    _searchController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();

    super.dispose();
  }

  BookQuery get _currentUrlQuery {
    final uri = GoRouterState.of(context).uri;

    return BookQuery.fromQueryParameters(
      uri.queryParameters,
    );
  }

  void _goToQuery(BookQuery query) {
    final uri = Uri(
      path: '/books',
      queryParameters: query.toQueryParameters(),
    );

    context.go(uri.toString());
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () {
        if (!mounted) {
          return;
        }

        _goToQuery(
          _currentUrlQuery.copyWith(
            search: value,
          ),
        );
      },
    );
  }

  void _applyYears() {
    _searchDebounce?.cancel();

    final yearFrom = int.tryParse(
      _yearFromController.text.trim(),
    );

    final yearTo = int.tryParse(
      _yearToController.text.trim(),
    );

    _goToQuery(
      _currentUrlQuery.copyWith(
        search: _searchController.text,
        yearFrom: yearFrom,
        yearTo: yearTo,
      ),
    );
  }

  void _resetFilters() {
    _searchDebounce?.cancel();

    _searchController.clear();
    _yearFromController.clear();
    _yearToController.clear();

    _goToQuery(
      const BookQuery(),
    );
  }

  Future<bool> _confirm(
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Подтвердить'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _deleteSelected(
    BookListNotifier notifier,
  ) async {
    final confirmed = await _confirm(
      'Удаление выбранных книг',
      'Логически удалить выбранные записи '
          '(${notifier.selectedCount})?',
    );

    if (!confirmed) {
      return;
    }

    await notifier.deleteSelected();
  }

  Future<void> _softDelete(
    BookListNotifier notifier,
    Book book,
  ) async {
    final confirmed = await _confirm(
      'Удаление книги',
      'Логически удалить книгу '
          '«${book.title}»?',
    );

    if (!confirmed) {
      return;
    }

    await notifier.softDelete(book.id);
  }

  Future<void> _hardDelete(
    BookListNotifier notifier,
    Book book,
  ) async {
    final confirmed = await _confirm(
      'Физическое удаление',
      'Удалить книгу «${book.title}» '
          'без возможности восстановления?',
    );

    if (!confirmed) {
      return;
    }

    await notifier.hardDelete(book.id);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final query = _currentUrlQuery;

    final queryIsLoading =
        notifier.query != query;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Каталог книг',
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.go('/authors');
            },
            icon: const Icon(
              Icons.people,
            ),
            label: const Text(
              'Авторы',
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(query),

          if (notifier.hasSelection)
            _buildSelectionBar(notifier),

          const Divider(height: 1),

          Expanded(
            child: queryIsLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _buildBody(notifier),
          ),

          if (!queryIsLoading &&
              notifier.status == LoadStatus.success)
            PaginationControls(
              page: notifier.result.page,
              totalPages: notifier.result.totalPages,
              total: notifier.result.total,
              size: notifier.result.size,
              onPageChanged: (page) {
                _goToQuery(
                  query.copyWith(
                    page: page,
                  ),
                );
              },
              onSizeChanged: (size) {
                _goToQuery(
                  query.copyWith(
                    size: size,
                    page: 1,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(BookQuery query) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                labelText: 'Поиск',
                hintText: 'Название или ISBN',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          SizedBox(
            width: 190,
            child: DropdownButtonFormField<int>(
              initialValue: query.genreId ?? 0,
              decoration: const InputDecoration(
                labelText: 'Жанр',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Все жанры'),
                ),
                for (final entry in seedGenres.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
              ],
              onChanged: (value) {
                _searchDebounce?.cancel();

                _goToQuery(
                  query.copyWith(
                    search: _searchController.text,
                    genreId:
                        value == null || value == 0
                            ? null
                            : value,
                  ),
                );
              },
            ),
          ),

          SizedBox(
            width: 210,
            child: DropdownButtonFormField<int>(
              initialValue: query.publisherId ?? 0,
              decoration: const InputDecoration(
                labelText: 'Издательство',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Все издательства'),
                ),
                for (final entry
                    in seedPublishers.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
              ],
              onChanged: (value) {
                _searchDebounce?.cancel();

                _goToQuery(
                  query.copyWith(
                    search: _searchController.text,
                    publisherId:
                        value == null || value == 0
                            ? null
                            : value,
                  ),
                );
              },
            ),
          ),

          SizedBox(
            width: 130,
            child: TextField(
              controller: _yearFromController,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _applyYears(),
              decoration: const InputDecoration(
                labelText: 'Год от',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          SizedBox(
            width: 130,
            child: TextField(
              controller: _yearToController,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _applyYears(),
              decoration: const InputDecoration(
                labelText: 'Год до',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          FilledButton.tonalIcon(
            onPressed: _applyYears,
            icon: const Icon(Icons.filter_alt),
            label: const Text('Применить годы'),
          ),

          FilterChip(
            label: const Text(
              'Показывать удалённые',
            ),
            selected: query.includeDeleted,
            onSelected: (selected) {
              _searchDebounce?.cancel();

              _goToQuery(
                query.copyWith(
                  search: _searchController.text,
                  includeDeleted: selected,
                ),
              );
            },
          ),

          TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(
              Icons.filter_alt_off,
            ),
            label: const Text(
              'Сбросить',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(
    BookListNotifier notifier,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Выбрано: ${notifier.selectedCount}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          FilledButton.icon(
            onPressed: () {
              _deleteSelected(notifier);
            },
            icon: const Icon(
              Icons.delete_outline,
            ),
            label: const Text(
              'Удалить выбранные',
            ),
          ),

          TextButton(
            onPressed: notifier.clearSelection,
            child: const Text(
              'Снять выделение',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BookListNotifier notifier,
  ) {
    return switch (notifier.status) {
      LoadStatus.idle ||
      LoadStatus.loading =>
        const Center(
          child: CircularProgressIndicator(),
        ),

      LoadStatus.error => _ErrorView(
          message:
              notifier.error ?? 'Неизвестная ошибка',
          onRetry: notifier.load,
        ),

      LoadStatus.success =>
        notifier.result.items.isEmpty
            ? const _EmptyView()
            : LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  if (constraints.maxWidth < 600) {
                    return _BooksCards(
                      notifier: notifier,
                      onRestore: notifier.restore,
                      onSoftDelete: (book) {
                        _softDelete(
                          notifier,
                          book,
                        );
                      },
                      onHardDelete: (book) {
                        _hardDelete(
                          notifier,
                          book,
                        );
                      },
                    );
                  }

                  return _BooksTable(
                    notifier: notifier,
                    onSort: (field) {
                      final current =
                          notifier.query;

                      final sameField =
                          field ==
                              current.sortField;

                      _goToQuery(
                        current.copyWith(
                          sortField: field,
                          sortAscending:
                              sameField
                                  ? !current
                                      .sortAscending
                                  : true,
                        ),
                      );
                    },
                    onRestore: notifier.restore,
                    onSoftDelete: (book) {
                      _softDelete(
                        notifier,
                        book,
                      );
                    },
                    onHardDelete: (book) {
                      _hardDelete(
                        notifier,
                        book,
                      );
                    },
                  );
                },
              ),
    };
  }
}

class _BooksTable extends StatelessWidget {
  final BookListNotifier notifier;
  final ValueChanged<String> onSort;
  final ValueChanged<int> onRestore;
  final ValueChanged<Book> onSoftDelete;
  final ValueChanged<Book> onHardDelete;

  const _BooksTable({
    required this.notifier,
    required this.onSort,
    required this.onRestore,
    required this.onSoftDelete,
    required this.onHardDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: EntityTable<Book>(
        items: notifier.result.items,
        idOf: (book) => book.id,

        selected: notifier.selected,
        onToggleSelect:
            notifier.toggleSelection,

        sortField: notifier.query.sortField,
        sortAscending:
            notifier.query.sortAscending,
        onSort: onSort,

        columns: [
          TableColumnSpec<Book>(
            label: 'Название',
            sortField: 'title',
            build: (book) {
              return Text(
                book.title,
                style: TextStyle(
                  decoration: book.isDeleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              );
            },
          ),

          TableColumnSpec<Book>(
            label: 'ISBN',
            build: (book) => Text(book.isbn),
          ),

          TableColumnSpec<Book>(
            label: 'Год',
            sortField: 'year',
            numeric: true,
            build: (book) =>
                Text('${book.year}'),
          ),

          TableColumnSpec<Book>(
            label: 'Страниц',
            sortField: 'pages',
            numeric: true,
            build: (book) =>
                Text('${book.pages}'),
          ),

          TableColumnSpec<Book>(
            label: 'Доступно',
            numeric: true,
            build: (book) => Text(
              '${book.copiesAvailable}/'
              '${book.copiesTotal}',
            ),
          ),
        ],

        actions: (book) {
          return [
            IconButton(
              tooltip: 'Открыть карточку',
              onPressed: () {
                context.push(
                  '/books/${book.id}',
                );
              },
              icon: const Icon(
                Icons.open_in_new,
              ),
            ),

            if (book.isDeleted)
              IconButton(
                tooltip: 'Восстановить',
                onPressed: () {
                  onRestore(book.id);
                },
                icon: const Icon(
                  Icons.restore,
                ),
              )
            else
              IconButton(
                tooltip: 'Логически удалить',
                onPressed: () {
                  onSoftDelete(book);
                },
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),

            IconButton(
              tooltip: 'Удалить навсегда',
              onPressed: () {
                onHardDelete(book);
              },
              icon: const Icon(
                Icons.delete_forever,
              ),
            ),
          ];
        },
      ),
    );
  }
}

class _BooksCards extends StatelessWidget {
  final BookListNotifier notifier;
  final ValueChanged<int> onRestore;
  final ValueChanged<Book> onSoftDelete;
  final ValueChanged<Book> onHardDelete;

  const _BooksCards({
    required this.notifier,
    required this.onRestore,
    required this.onSoftDelete,
    required this.onHardDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notifier.result.items.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book =
            notifier.result.items[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                CheckboxListTile(
                  value: notifier.selected
                      .contains(book.id),
                  onChanged: (_) {
                    notifier.toggleSelection(
                      book.id,
                    );
                  },
                  title: Text(
                    book.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: book.isDeleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(top: 8),
                    child: Text(
                      'ISBN: ${book.isbn}\n'
                      'Год: ${book.year}\n'
                      'Страниц: ${book.pages}\n'
                      'Доступно: '
                      '${book.copiesAvailable}/'
                      '${book.copiesTotal}'
                      '${book.isDeleted ? '\nУДАЛЕНА' : ''}',
                    ),
                  ),
                  controlAffinity:
                      ListTileControlAffinity.leading,
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        context.push(
                          '/books/${book.id}',
                        );
                      },
                      icon: const Icon(
                        Icons.visibility_outlined,
                      ),
                      label: const Text(
                        'Открыть',
                      ),
                    ),

                    if (book.isDeleted)
                      TextButton.icon(
                        onPressed: () {
                          onRestore(book.id);
                        },
                        icon: const Icon(
                          Icons.restore,
                        ),
                        label: const Text(
                          'Восстановить',
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () {
                          onSoftDelete(book);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
                        label: const Text(
                          'Удалить',
                        ),
                      ),

                    IconButton(
                      tooltip: 'Удалить навсегда',
                      onPressed: () {
                        onHardDelete(book);
                      },
                      icon: const Icon(
                        Icons.delete_forever,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'По заданным условиям '
            'ничего не найдено',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Повторить',
              ),
            ),
          ],
        ),
      ),
    );
  }
}