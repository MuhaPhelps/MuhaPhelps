import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../state/author_list_notifier.dart';

class AuthorDetailScreen
    extends StatefulWidget {
  final int authorId;

  const AuthorDetailScreen({
    super.key,
    required this.authorId,
  });

  @override
  State<AuthorDetailScreen> createState() =>
      _AuthorDetailScreenState();
}

class _AuthorDetailScreenState
    extends State<AuthorDetailScreen> {
  Future<Author?>? _authorFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _authorFuture ??= context
        .read<AuthorListNotifier>()
        .findById(widget.authorId);
  }

  @override
  void didUpdateWidget(
    covariant AuthorDetailScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.authorId !=
        widget.authorId) {
      _authorFuture = context
          .read<AuthorListNotifier>()
          .findById(widget.authorId);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/authors');
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: _goBack,
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
        title: const Text(
          'Карточка автора',
        ),
      ),
      body: FutureBuilder<Author?>(
        future: _authorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: '
                '${snapshot.error}',
              ),
            );
          }

          final author = snapshot.data;

          if (author == null) {
            return const _NotFoundView();
          }

          return Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 600,
                ),
                child: Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 32,
                              child: Icon(
                                Icons.person,
                                size: 36,
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: Text(
                                author.fullName,
                                style:
                                    Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        _DetailRow(
                          label: 'ID',
                          value: '${author.id}',
                        ),

                        _DetailRow(
                          label: 'ФИО',
                          value:
                              author.fullName,
                        ),

                        _DetailRow(
                          label: 'Год рождения',
                          value:
                              author.birthYear
                                      ?.toString() ??
                                  'Не указан',
                        ),

                        _DetailRow(
                          label: 'Страна',
                          value: author.country,
                        ),

                        _DetailRow(
                          label: 'Статус',
                          value: author.isDeleted
                              ? 'Удалён'
                              : 'Активен',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _NotFoundView
    extends StatelessWidget {
  const _NotFoundView();

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
            Icons.person_off_outlined,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'Автор не найден',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}