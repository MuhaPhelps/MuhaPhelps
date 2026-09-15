import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import '../state/author_list_notifier.dart';
import '../state/book_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class AuthorsScreen extends StatefulWidget {
  const AuthorsScreen({super.key});

  @override
  State<AuthorsScreen> createState() =>
      _AuthorsScreenState();
}

class _AuthorsScreenState
    extends State<AuthorsScreen> {
  final _searchController =
      TextEditingController();

  Timer? _searchDebounce;
  Uri? _lastUri;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final uri =
        GoRouterState.of(context).uri;

    if (_lastUri == uri) {
      return;
    }

    _lastUri = uri;

    final query =
        AuthorQuery.fromQueryParameters(
      uri.queryParameters,
    );

    _searchController.text =
        query.search;

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final notifier =
          context.read<AuthorListNotifier>();

      if (notifier.query != query ||
          notifier.status ==
              LoadStatus.idle) {
        notifier.applyQuery(query);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  AuthorQuery get _currentUrlQuery {
    final uri =
        GoRouterState.of(context).uri;

    return AuthorQuery
        .fromQueryParameters(
      uri.queryParameters,
    );
  }

  void _goToQuery(
    AuthorQuery query,
  ) {
    final uri = Uri(
      path: '/authors',
      queryParameters:
          query.toQueryParameters(),
    );

    context.go(uri.toString());
  }

  void _onSearchChanged(
    String value,
  ) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(
        milliseconds: 400,
      ),
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

  void _resetFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();

    _goToQuery(
      const AuthorQuery(),
    );
  }

  Future<bool> _confirm(
    String title,
    String message,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false);
              },
              child: const Text(
                'Отмена',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true);
              },
              child: const Text(
                'Подтвердить',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _deleteSelected(
    AuthorListNotifier notifier,
  ) async {
    final confirmed = await _confirm(
      'Удаление авторов',
      'Логически удалить выбранные '
          'записи '
          '(${notifier.selectedCount})?',
    );

    if (!confirmed) {
      return;
    }

    await notifier.deleteSelected();
  }

  Future<void> _softDelete(
    AuthorListNotifier notifier,
    Author author,
  ) async {
    final confirmed = await _confirm(
      'Удаление автора',
      'Логически удалить автора '
          '«${author.fullName}»?',
    );

    if (!confirmed) {
      return;
    }

    await notifier.softDelete(
      author.id,
    );
  }

  Future<void> _hardDelete(
    AuthorListNotifier notifier,
    Author author,
  ) async {
    final confirmed = await _confirm(
      'Физическое удаление',
      'Удалить автора '
          '«${author.fullName}» '
          'без возможности восстановления?',
    );

    if (!confirmed) {
      return;
    }

    await notifier.hardDelete(
      author.id,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final notifier =
        context.watch<AuthorListNotifier>();

    final query =
        _currentUrlQuery;

    final queryIsLoading =
        notifier.query != query;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Авторы',
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.go('/books');
            },
            icon: const Icon(
              Icons.menu_book,
            ),
            label: const Text(
              'Книги',
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(query),

          if (notifier.hasSelection)
            _buildSelectionBar(
              notifier,
            ),

          const Divider(height: 1),

          Expanded(
            child: queryIsLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : _buildBody(
                    notifier,
                  ),
          ),

          if (!queryIsLoading &&
              notifier.status ==
                  LoadStatus.success)
            PaginationControls(
              page:
                  notifier.result.page,
              totalPages:
                  notifier
                      .result.totalPages,
              total:
                  notifier.result.total,
              size:
                  notifier.result.size,
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

  Widget _buildFilters(
    AuthorQuery query,
  ) {
    return Padding(
      padding:
          const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment:
            WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller:
                  _searchController,
              onChanged:
                  _onSearchChanged,
              decoration:
                  const InputDecoration(
                labelText: 'Поиск',
                hintText:
                    'ФИО или страна',
                prefixIcon:
                    Icon(Icons.search),
                border:
                    OutlineInputBorder(),
              ),
            ),
          ),

          FilterChip(
            label: const Text(
              'Показывать удалённых',
            ),
            selected:
                query.includeDeleted,
            onSelected: (selected) {
              _searchDebounce
                  ?.cancel();

              _goToQuery(
                query.copyWith(
                  search:
                      _searchController.text,
                  includeDeleted:
                      selected,
                ),
              );
            },
          ),

          TextButton.icon(
            onPressed:
                _resetFilters,
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
    AuthorListNotifier notifier,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment:
            WrapCrossAlignment.center,
        children: [
          Text(
            'Выбрано: '
            '${notifier.selectedCount}',
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          FilledButton.icon(
            onPressed: () {
              _deleteSelected(
                notifier,
              );
            },
            icon: const Icon(
              Icons.delete_outline,
            ),
            label: const Text(
              'Удалить выбранных',
            ),
          ),

          TextButton(
            onPressed:
                notifier.clearSelection,
            child: const Text(
              'Снять выделение',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AuthorListNotifier notifier,
  ) {
    return switch (notifier.status) {
      LoadStatus.idle ||
      LoadStatus.loading =>
        const Center(
          child:
              CircularProgressIndicator(),
        ),

      LoadStatus.error =>
        _ErrorView(
          message:
              notifier.error ??
                  'Неизвестная ошибка',
          onRetry:
              notifier.load,
        ),

      LoadStatus.success =>
        notifier.result.items.isEmpty
            ? const _EmptyView()
            : LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  if (constraints
                          .maxWidth <
                      600) {
                    return _AuthorsCards(
                      notifier:
                          notifier,
                      onRestore:
                          notifier
                              .restore,
                      onSoftDelete:
                          (author) {
                        _softDelete(
                          notifier,
                          author,
                        );
                      },
                      onHardDelete:
                          (author) {
                        _hardDelete(
                          notifier,
                          author,
                        );
                      },
                    );
                  }

                  return _AuthorsTable(
                    notifier:
                        notifier,

                    onSort: (field) {
                      final current =
                          notifier.query;

                      final sameField =
                          field ==
                              current
                                  .sortField;

                      _goToQuery(
                        current.copyWith(
                          sortField:
                              field,
                          sortAscending:
                              sameField
                                  ? !current
                                      .sortAscending
                                  : true,
                        ),
                      );
                    },

                    onRestore:
                        notifier.restore,

                    onSoftDelete:
                        (author) {
                      _softDelete(
                        notifier,
                        author,
                      );
                    },

                    onHardDelete:
                        (author) {
                      _hardDelete(
                        notifier,
                        author,
                      );
                    },
                  );
                },
              ),
    };
  }
}

class _AuthorsTable
    extends StatelessWidget {
  final AuthorListNotifier notifier;

  final ValueChanged<String>
      onSort;

  final ValueChanged<int>
      onRestore;

  final ValueChanged<Author>
      onSoftDelete;

  final ValueChanged<Author>
      onHardDelete;

  const _AuthorsTable({
    required this.notifier,
    required this.onSort,
    required this.onRestore,
    required this.onSoftDelete,
    required this.onHardDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(16),
      child: EntityTable<Author>(
        items:
            notifier.result.items,

        idOf:
            (author) => author.id,

        selected:
            notifier.selected,

        onToggleSelect:
            notifier.toggleSelection,

        sortField:
            notifier.query.sortField,

        sortAscending:
            notifier
                .query.sortAscending,

        onSort:
            onSort,

        columns: [
          TableColumnSpec<Author>(
            label: 'ФИО',
            sortField:
                'fullName',
            build: (author) {
              return Text(
                author.fullName,
                style: TextStyle(
                  decoration:
                      author.isDeleted
                          ? TextDecoration
                              .lineThrough
                          : null,
                ),
              );
            },
          ),

          TableColumnSpec<Author>(
            label:
                'Год рождения',
            sortField:
                'birthYear',
            numeric: true,
            build: (author) {
              return Text(
                author.birthYear
                        ?.toString() ??
                    '—',
              );
            },
          ),

          TableColumnSpec<Author>(
            label: 'Страна',
            sortField:
                'country',
            build: (author) {
              return Text(
                author.country,
              );
            },
          ),
        ],

        actions: (author) {
          return [
            IconButton(
              tooltip:
                  'Открыть карточку',
              onPressed: () {
                context.push(
                  '/authors/'
                  '${author.id}',
                );
              },
              icon: const Icon(
                Icons.open_in_new,
              ),
            ),

            if (author.isDeleted)
              IconButton(
                tooltip:
                    'Восстановить',
                onPressed: () {
                  onRestore(
                    author.id,
                  );
                },
                icon: const Icon(
                  Icons.restore,
                ),
              )
            else
              IconButton(
                tooltip:
                    'Логически удалить',
                onPressed: () {
                  onSoftDelete(
                    author,
                  );
                },
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),

            IconButton(
              tooltip:
                  'Удалить навсегда',
              onPressed: () {
                onHardDelete(
                  author,
                );
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

class _AuthorsCards
    extends StatelessWidget {
  final AuthorListNotifier notifier;

  final ValueChanged<int>
      onRestore;

  final ValueChanged<Author>
      onSoftDelete;

  final ValueChanged<Author>
      onHardDelete;

  const _AuthorsCards({
    required this.notifier,
    required this.onRestore,
    required this.onSoftDelete,
    required this.onHardDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView.separated(
      padding:
          const EdgeInsets.all(16),

      itemCount:
          notifier.result.items.length,

      separatorBuilder: (_, _) =>
          const SizedBox(
        height: 8,
      ),

      itemBuilder: (
        context,
        index,
      ) {
        final author =
            notifier
                .result.items[index];

        return Card(
          child: Padding(
            padding:
                const EdgeInsets.all(8),
            child: Column(
              children: [
                CheckboxListTile(
                  value: notifier
                      .selected
                      .contains(
                        author.id,
                      ),
                  onChanged: (_) {
                    notifier
                        .toggleSelection(
                      author.id,
                    );
                  },
                  title: Text(
                    author.fullName,
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      decoration:
                          author.isDeleted
                              ? TextDecoration
                                  .lineThrough
                              : null,
                    ),
                  ),
                  subtitle: Text(
                    'Год рождения: '
                    '${author.birthYear ?? 'не указан'}\n'
                    'Страна: '
                    '${author.country}'
                    '${author.isDeleted ? '\nУДАЛЁН' : ''}',
                  ),
                  controlAffinity:
                      ListTileControlAffinity
                          .leading,
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        context.push(
                          '/authors/'
                          '${author.id}',
                        );
                      },
                      icon: const Icon(
                        Icons
                            .visibility_outlined,
                      ),
                      label:
                          const Text(
                        'Открыть',
                      ),
                    ),

                    if (author.isDeleted)
                      TextButton.icon(
                        onPressed: () {
                          onRestore(
                            author.id,
                          );
                        },
                        icon:
                            const Icon(
                          Icons.restore,
                        ),
                        label:
                            const Text(
                          'Восстановить',
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () {
                          onSoftDelete(
                            author,
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .delete_outline,
                        ),
                        label:
                            const Text(
                          'Удалить',
                        ),
                      ),

                    IconButton(
                      tooltip:
                          'Удалить навсегда',
                      onPressed: () {
                        onHardDelete(
                          author,
                        );
                      },
                      icon: const Icon(
                        Icons
                            .delete_forever,
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

class _EmptyView
    extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'Авторы не найдены',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView
    extends StatelessWidget {
  final String message;

  final Future<void> Function()
      onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton.icon(
              onPressed:
                  onRetry,
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