import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/reader.dart';
import '../models/reader_query.dart';
import '../state/book_list_notifier.dart';
import '../state/reader_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class ReadersScreen
    extends StatefulWidget {
  const ReadersScreen({
    super.key,
  });

  @override
  State<ReadersScreen>
      createState() =>
          _ReadersScreenState();
}

class _ReadersScreenState
    extends State<ReadersScreen> {
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
        ReaderQuery.fromQueryParameters(
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
              ReaderListNotifier>();

      if (notifier.query != query ||
          notifier.status ==
              LoadStatus.idle) {
        notifier.applyQuery(
          query,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  ReaderQuery get _currentQuery {
    return ReaderQuery
        .fromQueryParameters(
      GoRouterState.of(context)
          .uri
          .queryParameters,
    );
  }

  void _goToQuery(
    ReaderQuery query,
  ) {
    context.go(
      Uri(
        path: '/readers',
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
          builder: (
            context,
          ) {
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

  Future<void> _handleAction(
    ReaderListNotifier notifier,
    Reader reader,
    String action,
  ) async {
    if (action == 'open') {
      context.push(
        '/readers/${reader.id}',
      );

      return;
    }

    if (action == 'restore') {
      await notifier.restore(
        reader.id,
      );

      return;
    }

    if (action == 'soft') {
      final confirmed =
          await _confirm(
        'Удаление читателя',
        'Логически удалить '
            'читателя '
            '«${reader.fullName}»?',
      );

      if (confirmed) {
        await notifier.softDelete(
          reader.id,
        );
      }

      return;
    }

    if (action == 'hard') {
      final confirmed =
          await _confirm(
        'Физическое удаление',
        'Удалить читателя '
            '«${reader.fullName}» '
            'навсегда?',
      );

      if (confirmed) {
        await notifier.hardDelete(
          reader.id,
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final notifier =
        context.watch<
            ReaderListNotifier>();

    final query =
        _currentQuery;

    final loadingQuery =
        notifier.query != query;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Читатели',
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
          TextButton(
            onPressed: () {
              context.go(
                '/publishers',
              );
            },
            child: const Text(
              'Издательства',
            ),
          ),
          const SizedBox(
            width: 8,
          ),
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
                  WrapCrossAlignment
                      .center,
              children: [
                SizedBox(
                  width: 340,
                  child: TextField(
                    controller:
                        _searchController,
                    onChanged:
                        _onSearchChanged,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Поиск',
                      hintText:
                          'ФИО, email, телефон или билет',
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
                    'Показывать удалённых',
                  ),
                  selected:
                      query.includeDeleted,
                  onSelected: (
                    value,
                  ) {
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
                      const ReaderQuery(),
                    );
                  },
                  icon: const Icon(
                    Icons
                        .filter_alt_off,
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
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Wrap(
                spacing: 12,
                crossAxisAlignment:
                    WrapCrossAlignment
                        .center,
                children: [
                  Text(
                    'Выбрано: '
                    '${notifier.selectedCount}',
                  ),

                  FilledButton.icon(
                    onPressed:
                        () async {
                      final confirmed =
                          await _confirm(
                        'Удаление читателей',
                        'Логически удалить '
                            'выбранные записи?',
                      );

                      if (confirmed) {
                        await notifier
                            .deleteSelected();
                      }
                    },
                    icon: const Icon(
                      Icons
                          .delete_outline,
                    ),
                    label: const Text(
                      'Удалить выбранных',
                    ),
                  ),

                  TextButton(
                    onPressed:
                        notifier
                            .clearSelection,
                    child: const Text(
                      'Снять выделение',
                    ),
                  ),
                ],
              ),
            ),

          const Divider(
            height: 1,
          ),

          Expanded(
            child: loadingQuery
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : _buildBody(
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
              onPageChanged: (
                page,
              ) {
                _goToQuery(
                  query.copyWith(
                    page: page,
                  ),
                );
              },
              onSizeChanged: (
                size,
              ) {
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
    ReaderListNotifier notifier,
  ) {
    if (notifier.status ==
            LoadStatus.idle ||
        notifier.status ==
            LoadStatus.loading) {
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
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 12,
            ),
            FilledButton.icon(
              onPressed:
                  notifier.load,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Повторить',
              ),
            ),
          ],
        ),
      );
    }

    if (notifier
        .result.items.isEmpty) {
      return const Center(
        child: Text(
          'Читатели не найдены',
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
          return ListView.separated(
            padding:
                const EdgeInsets.all(
              16,
            ),
            itemCount: notifier
                .result.items.length,
            separatorBuilder:
                (_, _) =>
                    const SizedBox(
              height: 8,
            ),
            itemBuilder: (
              context,
              index,
            ) {
              final reader =
                  notifier
                      .result
                      .items[index];

              return Card(
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: notifier
                          .selected
                          .contains(
                            reader.id,
                          ),
                      onChanged: (_) {
                        notifier
                            .toggleSelection(
                          reader.id,
                        );
                      },
                      title: Text(
                        reader.fullName,
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          decoration:
                              reader.isDeleted
                                  ? TextDecoration
                                      .lineThrough
                                  : null,
                        ),
                      ),
                      subtitle: Text(
                        '${reader.email}\n'
                        '${reader.phone}\n'
                        'Билет: '
                        '${reader.card.number}',
                      ),
                      isThreeLine:
                          true,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .end,
                      children: [
                        TextButton.icon(
                          onPressed:
                              () {
                            context.push(
                              '/readers/'
                              '${reader.id}',
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .visibility_outlined,
                          ),
                          label:
                              const Text(
                            'Открыть',
                          ),
                        ),

                        if (reader
                            .isDeleted)
                          TextButton.icon(
                            onPressed:
                                () {
                              notifier
                                  .restore(
                                reader.id,
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
                            onPressed:
                                () {
                              _handleAction(
                                notifier,
                                reader,
                                'soft',
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
                          onPressed:
                              () {
                            _handleAction(
                              notifier,
                              reader,
                              'hard',
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .delete_forever,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }

        return SingleChildScrollView(
          padding:
              const EdgeInsets.all(16),
          child:
              EntityTable<Reader>(
            items:
                notifier.result.items,

            idOf:
                (reader) =>
                    reader.id,

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

            onSort: (
              field,
            ) {
              final current =
                  notifier.query;

              _goToQuery(
                current.copyWith(
                  sortField:
                      field,
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
                  Reader>(
                label: 'ФИО',
                sortField:
                    'fullName',
                build: (
                  reader,
                ) {
                  return Text(
                    reader.fullName,
                    style:
                        TextStyle(
                      decoration:
                          reader
                                  .isDeleted
                              ? TextDecoration
                                  .lineThrough
                              : null,
                    ),
                  );
                },
              ),

              TableColumnSpec<
                  Reader>(
                label: 'Email',
                sortField:
                    'email',
                build: (
                  reader,
                ) =>
                    Text(
                  reader.email,
                ),
              ),

              TableColumnSpec<
                  Reader>(
                label:
                    'Телефон',
                sortField:
                    'phone',
                build: (
                  reader,
                ) =>
                    Text(
                  reader.phone,
                ),
              ),

              TableColumnSpec<
                  Reader>(
                label:
                    'Билет',
                build: (
                  reader,
                ) =>
                    Text(
                  reader
                      .card.number,
                ),
              ),
            ],

            actions: (
              reader,
            ) =>
                [
              IconButton(
                tooltip:
                    'Открыть карточку',
                onPressed: () {
                  context.push(
                    '/readers/'
                    '${reader.id}',
                  );
                },
                icon: const Icon(
                  Icons.open_in_new,
                ),
              ),

              if (reader.isDeleted)
                IconButton(
                  tooltip:
                      'Восстановить',
                  onPressed: () {
                    notifier.restore(
                      reader.id,
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
                      reader,
                      'soft',
                    );
                  },
                  icon: const Icon(
                    Icons
                        .delete_outline,
                  ),
                ),

              IconButton(
                tooltip:
                    'Удалить навсегда',
                onPressed: () {
                  _handleAction(
                    notifier,
                    reader,
                    'hard',
                  );
                },
                icon: const Icon(
                  Icons
                      .delete_forever,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}