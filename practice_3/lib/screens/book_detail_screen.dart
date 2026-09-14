import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/book.dart';
import '../state/book_list_notifier.dart';

class BookDetailScreen extends StatefulWidget {
  final int bookId;

  const BookDetailScreen({
    super.key,
    required this.bookId,
  });

  @override
  State<BookDetailScreen> createState() =>
      _BookDetailScreenState();
}

class _BookDetailScreenState
    extends State<BookDetailScreen> {
  Future<Book?>? _bookFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _bookFuture ??= context
        .read<BookListNotifier>()
        .findById(widget.bookId);
  }

  @override
  void didUpdateWidget(
    covariant BookDetailScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.bookId != widget.bookId) {
      _bookFuture = context
          .read<BookListNotifier>()
          .findById(widget.bookId);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/books');
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
          'Карточка книги',
        ),
      ),
      body: FutureBuilder<Book?>(
        future: _bookFuture,
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

          final book = snapshot.data;

          if (book == null) {
            return const _NotFoundView(
              message: 'Книга не найдена',
            );
          }

          return _BookDetails(
            book: book,
          );
        },
      ),
    );
  }
}

class _BookDetails extends StatelessWidget {
  final Book book;

  const _BookDetails({
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    final publisher =
        seedPublishers[book.publisherId] ??
            'Неизвестно';

    final genres = book.genreIds
        .map(
          (id) => seedGenres[id] ?? 'Жанр $id',
        )
        .join(', ');

    final authors = seedAuthors
        .where(
          (author) =>
              book.authorIds.contains(author.id),
        )
        .map(
          (author) => author.fullName,
        )
        .join(', ');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
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
                      const Icon(
                        Icons.menu_book,
                        size: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          book.title,
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
                    value: '${book.id}',
                  ),

                  _DetailRow(
                    label: 'ISBN',
                    value: book.isbn,
                  ),

                  _DetailRow(
                    label: 'Авторы',
                    value: authors.isEmpty
                        ? 'Не указаны'
                        : authors,
                  ),

                  _DetailRow(
                    label: 'Жанры',
                    value: genres.isEmpty
                        ? 'Не указаны'
                        : genres,
                  ),

                  _DetailRow(
                    label: 'Издательство',
                    value: publisher,
                  ),

                  _DetailRow(
                    label: 'Год издания',
                    value: '${book.year}',
                  ),

                  _DetailRow(
                    label: 'Количество страниц',
                    value: '${book.pages}',
                  ),

                  _DetailRow(
                    label: 'Всего экземпляров',
                    value: '${book.copiesTotal}',
                  ),

                  _DetailRow(
                    label: 'Доступно',
                    value:
                        '${book.copiesAvailable}',
                  ),

                  _DetailRow(
                    label: 'Статус',
                    value: book.isDeleted
                        ? 'Удалена'
                        : 'Активна',
                  ),
                ],
              ),
            ),
          ),
        ),
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
      padding:
          const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
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

class _NotFoundView extends StatelessWidget {
  final String message;

  const _NotFoundView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}