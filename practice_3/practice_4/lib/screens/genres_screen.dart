import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/genre.dart';
import '../models/genre_query.dart';
import '../state/book_list_notifier.dart';
import '../state/genre_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class GenresScreen extends StatefulWidget {
  const GenresScreen({super.key});

  @override
  State<GenresScreen> createState() =>
      _GenresScreenState();
}

class _GenresScreenState
    extends State<GenresScreen> {
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
        GenreQuery.fromQueryParameters(
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
          context.read<GenreListNotifier>();

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

  GenreQuery get _currentQuery {
    return GenreQuery
        .fromQueryParameters(
      GoRouterState.of(context)
          .uri
          .queryParameters,
    );
  }

  void _goToQuery(
    GenreQuery query,
  ) {
    context.go(
      Uri(
        path: '/genres',
        queryParameters:
            query.toQueryParameters(),
      ).toString(),
    );
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
          _currentQuery.copyWith(
            search: value,
          ),
        );
      },
    );
  }

  Future<bool> _confirm(
    String title,
    String text,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(text),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      false,
                    );
                  },
                  child: const Text(
                    'Отмена',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      true,
                    );
                  },
                  child: const Text(
                    'Подтвердить',
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final notifier =
        context.watch<GenreListNotifier>();

    final query = _currentQuery;

    final loadingQuery =
        notifier.query != query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Жанры'),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/books');
            },
            child: const Text(
              'Книги',
            ),
          ),
          TextButton(
            onPressed: () {
              context.go('/authors');
            },
            child: const Text(
              'Авторы',
            ),
          ),
          TextButton(
            onPressed: () {
              context.go('/publishers');
            },
            child: const Text(
              'Издательства',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
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
                          'Название или описание',
                      prefixIcon:
                          Icon(Icons.search),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text(
                    'Показывать удалённые',
                  ),
                  selected:
                      query.includeDeleted,
                  onSelected: (value) {
                    _goToQuery(
                      query.copyWith(
                        includeDeleted:
                            value,
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: () {
                    _searchController
                        .clear();

                    _goToQuery(
                      const GenreQuery(),
                    );
                  },
                  icon: const Icon(
                    Icons.filter_alt_off,
                  ),
                  label: const Text(
                    'Сбросить',
                  ),
                ),
              ],
            ),
          ),
          if (notifier.hasSelection)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Wrap(
                spacing: 12,
                children: [
                  Text(
                    'Выбрано: '
                    '${notifier.selectedCount}',
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final ok =
                          await _confirm(
                        'Удаление жанров',
                        'Логически удалить '
                            'выбранные жанры?',
                      );

                      if (ok) {
                        await notifier
                            .deleteSelected();
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    label: const Text(
                      'Удалить выбранные',
                    ),
                  ),
                  TextButton(
                    onPressed: notifier
                        .clearSelection,
                    child: const Text(
                      'Снять выделение',
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: loadingQuery
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : _buildBody(
                    context,
                    notifier,
                  ),
          ),
          if (!loadingQuery &&
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

  Widget _buildBody(
    BuildContext context,
    GenreListNotifier notifier,
  ) {
    if (notifier.status ==
            LoadStatus.loading ||
        notifier.status ==
            LoadStatus.idle) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (notifier.status ==
        LoadStatus.error) {
      return Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              notifier.error ??
                  'Ошибка',
            ),
            const SizedBox(
              height: 12,
            ),
            FilledButton(
              onPressed: notifier.load,
              child: const Text(
                'Повторить',
              ),
            ),
          ],
        ),
      );
    }

    if (notifier.result.items.isEmpty) {
      return const Center(
        child: Text(
          'Жанры не найдены',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        if (constraints.maxWidth <
            600) {
          return ListView.builder(
            padding:
                const EdgeInsets.all(16),
            itemCount: notifier
                .result.items.length,
            itemBuilder: (
              context,
              index,
            ) {
              final genre = notifier
                  .result.items[index];

              return Card(
                child: ListTile(
                  leading: Checkbox(
                    value: notifier
                        .selected
                        .contains(
                          genre.id,
                        ),
                    onChanged: (_) {
                      notifier
                          .toggleSelection(
                        genre.id,
                      );
                    },
                  ),
                  title: Text(
                    genre.name,
                  ),
                  subtitle: Text(
                    genre.description,
                  ),
                  trailing: PopupMenuButton<
                      String>(
                    onSelected: (
                      value,
                    ) async {
                      await _handleAction(
                        notifier,
                        genre,
                        value,
                      );
                    },
                    itemBuilder:
                        (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Text(
                          'Открыть',
                        ),
                      ),
                      PopupMenuItem(
                        value: genre
                                .isDeleted
                            ? 'restore'
                            : 'soft',
                        child: Text(
                          genre.isDeleted
                              ? 'Восстановить'
                              : 'Удалить',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'hard',
                        child: Text(
                          'Удалить навсегда',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return SingleChildScrollView(
          padding:
              const EdgeInsets.all(16),
          child: EntityTable<Genre>(
            items:
                notifier.result.items,
            idOf:
                (genre) => genre.id,
            selected:
                notifier.selected,
            onToggleSelect:
                notifier
                    .toggleSelection,
            sortField:
                notifier
                    .query.sortField,
            sortAscending:
                notifier
                    .query
                    .sortAscending,
            onSort: (field) {
              final current =
                  notifier.query;

              _goToQuery(
                current.copyWith(
                  sortField: field,
                  sortAscending:
                      current.sortField ==
                              field
                          ? !current
                              .sortAscending
                          : true,
                ),
              );
            },
            columns: [
              TableColumnSpec<Genre>(
                label: 'Название',
                sortField: 'name',
                build: (genre) =>
                    Text(
                  genre.name,
                  style: TextStyle(
                    decoration:
                        genre.isDeleted
                            ? TextDecoration
                                .lineThrough
                            : null,
                  ),
                ),
              ),
              TableColumnSpec<Genre>(
                label: 'Описание',
                sortField:
                    'description',
                build: (genre) =>
                    Text(
                  genre.description,
                ),
              ),
            ],
            actions: (genre) => [
              IconButton(
                tooltip:
                    'Открыть карточку',
                onPressed: () {
                  context.push(
                    '/genres/${genre.id}',
                  );
                },
                icon: const Icon(
                  Icons.open_in_new,
                ),
              ),
              if (genre.isDeleted)
                IconButton(
                  tooltip:
                      'Восстановить',
                  onPressed: () {
                    notifier.restore(
                      genre.id,
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
                    _handleAction(
                      notifier,
                      genre,
                      'soft',
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
                  _handleAction(
                    notifier,
                    genre,
                    'hard',
                  );
                },
                icon: const Icon(
                  Icons.delete_forever,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAction(
    GenreListNotifier notifier,
    Genre genre,
    String action,
  ) async {
    if (action == 'open') {
      context.push(
        '/genres/${genre.id}',
      );

      return;
    }

    if (action == 'restore') {
      await notifier.restore(
        genre.id,
      );

      return;
    }

    if (action == 'soft') {
      final ok = await _confirm(
        'Удаление жанра',
        'Логически удалить '
            '«${genre.name}»?',
      );

      if (ok) {
        await notifier.softDelete(
          genre.id,
        );
      }

      return;
    }

    if (action == 'hard') {
      final ok = await _confirm(
        'Физическое удаление',
        'Удалить жанр '
            '«${genre.name}» навсегда?',
      );

      if (ok) {
        await notifier.hardDelete(
          genre.id,
        );
      }
    }
  }
}