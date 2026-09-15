import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../repositories/publisher_repository.dart';
import '../state/book_list_notifier.dart';
import '../state/publisher_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class PublishersScreen extends StatefulWidget {
  const PublishersScreen({
    super.key,
  });

  @override
  State<PublishersScreen> createState() =>
      _PublishersScreenState();
}

class _PublishersScreenState
    extends State<PublishersScreen> {
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
        PublisherQuery.fromQueryParameters(
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
          context.read<
              PublisherListNotifier>();

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

  PublisherQuery get _currentQuery {
    return PublisherQuery
        .fromQueryParameters(
      GoRouterState.of(context)
          .uri
          .queryParameters,
    );
  }

  void _goToQuery(
    PublisherQuery query,
  ) {
    context.go(
      Uri(
        path: '/publishers',
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

  Future<void> _showPublisherError(
    PublisherInUseException error,
  ) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Удаление невозможно',
          ),
          content: Text(
            'Издательство нельзя удалить, '
            'поскольку на него ссылаются '
            '${error.bookCount} книг.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Понятно',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier =
        context.watch<
            PublisherListNotifier>();

    final query = _currentQuery;

    final loadingQuery =
        notifier.query != query;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Издательства',
        ),
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
              context.go('/genres');
            },
            child: const Text(
              'Жанры',
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
                          'Название или город',
                      prefixIcon:
                          Icon(
                        Icons.search,
                      ),
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
                      const PublisherQuery(),
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
    PublisherListNotifier notifier,
  ) {
    if (notifier.status ==
            LoadStatus.loading ||
        notifier.status ==
            LoadStatus.idle) {
      return const Center(
        child:
            CircularProgressIndicator(),
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
              onPressed:
                  notifier.load,
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
          'Издательства не найдены',
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
              final publisher =
                  notifier
                      .result.items[index];

              return Card(
                child: ListTile(
                  title: Text(
                    publisher.name,
                  ),
                  subtitle: Text(
                    '${publisher.city}\n'
                    'Год основания: '
                    '${publisher.foundedYear ?? '—'}',
                  ),
                  isThreeLine: true,
                  trailing:
                      PopupMenuButton<
                          String>(
                    onSelected: (
                      action,
                    ) {
                      _handleAction(
                        notifier,
                        publisher,
                        action,
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
                        value: publisher
                                .isDeleted
                            ? 'restore'
                            : 'soft',
                        child: Text(
                          publisher
                                  .isDeleted
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
          child:
              EntityTable<Publisher>(
            items:
                notifier.result.items,
            idOf:
                (publisher) =>
                    publisher.id,
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
              TableColumnSpec<
                  Publisher>(
                label: 'Название',
                sortField: 'name',
                build: (publisher) {
                  return Text(
                    publisher.name,
                    style: TextStyle(
                      decoration:
                          publisher
                                  .isDeleted
                              ? TextDecoration
                                  .lineThrough
                              : null,
                    ),
                  );
                },
              ),
              TableColumnSpec<
                  Publisher>(
                label: 'Город',
                sortField: 'city',
                build: (publisher) =>
                    Text(
                  publisher.city,
                ),
              ),
              TableColumnSpec<
                  Publisher>(
                label:
                    'Год основания',
                sortField:
                    'foundedYear',
                numeric: true,
                build: (publisher) =>
                    Text(
                  publisher
                          .foundedYear
                          ?.toString() ??
                      '—',
                ),
              ),
            ],
            actions: (publisher) => [
              IconButton(
                tooltip:
                    'Открыть карточку',
                onPressed: () {
                  context.push(
                    '/publishers/'
                    '${publisher.id}',
                  );
                },
                icon: const Icon(
                  Icons.open_in_new,
                ),
              ),
              if (publisher.isDeleted)
                IconButton(
                  tooltip:
                      'Восстановить',
                  onPressed: () {
                    notifier.restore(
                      publisher.id,
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
                      publisher,
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
                    publisher,
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
    PublisherListNotifier notifier,
    Publisher publisher,
    String action,
  ) async {
    if (action == 'open') {
      context.push(
        '/publishers/${publisher.id}',
      );

      return;
    }

    if (action == 'restore') {
      await notifier.restore(
        publisher.id,
      );

      return;
    }

    if (action != 'soft' &&
        action != 'hard') {
      return;
    }

    final hard =
        action == 'hard';

    final confirmed = await _confirm(
      hard
          ? 'Физическое удаление'
          : 'Удаление издательства',
      hard
          ? 'Удалить издательство '
              '«${publisher.name}» навсегда?'
          : 'Логически удалить '
              'издательство '
              '«${publisher.name}»?',
    );

    if (!confirmed) {
      return;
    }

    try {
      if (hard) {
        await notifier.hardDelete(
          publisher.id,
        );
      } else {
        await notifier.softDelete(
          publisher.id,
        );
      }
    } on PublisherInUseException catch (error) {
      await _showPublisherError(
        error,
      );
    }
  }
}