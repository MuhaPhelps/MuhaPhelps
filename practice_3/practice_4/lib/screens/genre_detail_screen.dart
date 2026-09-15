import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/genre.dart';
import '../state/genre_list_notifier.dart';

class GenreDetailScreen extends StatefulWidget {
  final int genreId;

  const GenreDetailScreen({
    super.key,
    required this.genreId,
  });

  @override
  State<GenreDetailScreen> createState() =>
      _GenreDetailScreenState();
}

class _GenreDetailScreenState
    extends State<GenreDetailScreen> {
  Future<Genre?>? _genreFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _genreFuture ??= context
        .read<GenreListNotifier>()
        .findById(widget.genreId);
  }

  @override
  void didUpdateWidget(
    covariant GenreDetailScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.genreId != widget.genreId) {
      _genreFuture = context
          .read<GenreListNotifier>()
          .findById(widget.genreId);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/genres');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Карточка жанра',
        ),
      ),
      body: FutureBuilder<Genre?>(
        future: _genreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: ${snapshot.error}',
              ),
            );
          }

          final genre = snapshot.data;

          if (genre == null) {
            return const Center(
              child: Text(
                'Жанр не найден',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 650,
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 32,
                              child: Icon(
                                Icons.category,
                                size: 34,
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: Text(
                                genre.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _DetailRow(
                          label: 'ID',
                          value: '${genre.id}',
                        ),
                        _DetailRow(
                          label: 'Название',
                          value: genre.name,
                        ),
                        _DetailRow(
                          label: 'Описание',
                          value: genre.description,
                        ),
                        _DetailRow(
                          label: 'Статус',
                          value: genre.isDeleted
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
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