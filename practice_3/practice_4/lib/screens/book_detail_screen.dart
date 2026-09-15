import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../data/seed_data.dart';
import '../models/book.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../repositories/loan_repository.dart';
import '../repositories/reader_repository.dart';
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

  bool _issuing = false;

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

  void _reloadBook() {
    setState(() {
      _bookFuture = context
          .read<BookListNotifier>()
          .findById(widget.bookId);
    });
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _issueBook(
    Book book,
  ) async {
    if (_issuing) {
      return;
    }

    try {
      final readerRepository =
          context.read<ReaderRepository>();

      final readerResult =
          await readerRepository.find(
        const ReaderQuery(
          page: 1,
          size: 100,
        ),
      );

      if (!mounted) {
        return;
      }

      final readers = [
        ...readerResult.items,
      ];

      if (readers.isEmpty) {
        _showMessage(
          'Нет доступных читателей.',
        );
        return;
      }

      final input =
          await showDialog<_LoanInput>(
        context: context,
        builder: (
          dialogContext,
        ) {
          return _IssueBookDialog(
            book: book,
            readers: readers,
          );
        },
      );

      if (!mounted ||
          input == null) {
        return;
      }

      setState(() {
        _issuing = true;
      });

      try {
        await context
            .read<LoanRepository>()
            .issue(
          readerId:
              input.readerId,
          bookId:
              book.id,
          days:
              input.days,
        );

        if (!mounted) {
          return;
        }

        _showMessage(
          'Книга успешно выдана.',
        );

        _reloadBook();
      } on ConflictException catch (error) {
        _showMessage(
          'Конфликт: ${error.message}',
        );
      } on ApiException catch (error) {
        _showMessage(
          error.message,
        );
      } catch (error) {
        _showMessage(
          'Не удалось оформить выдачу: '
          '$error',
        );
      } finally {
        if (mounted) {
          setState(() {
            _issuing = false;
          });
        }
      }
    } on ApiException catch (error) {
      _showMessage(
        'Не удалось загрузить читателей: '
        '${error.message}',
      );
    } catch (error) {
      _showMessage(
        'Не удалось загрузить читателей: '
        '$error',
      );
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
        builder: (
          context,
          snapshot,
        ) {
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

          final book =
              snapshot.data;

          if (book == null) {
            return const _NotFoundView(
              message:
                  'Книга не найдена',
            );
          }

          return _BookDetails(
            book: book,
            issuing: _issuing,
            onIssue: () {
              _issueBook(book);
            },
          );
        },
      ),
    );
  }
}

class _BookDetails
    extends StatelessWidget {
  final Book book;
  final bool issuing;
  final VoidCallback onIssue;

  const _BookDetails({
    required this.book,
    required this.issuing,
    required this.onIssue,
  });

  @override
  Widget build(BuildContext context) {
    final publisher =
        seedPublishers[
                book.publisherId] ??
            'Неизвестно';

    final genres =
        book.genreIds
            .map(
              (id) =>
                  seedGenres[id] ??
                  'Жанр $id',
            )
            .join(', ');

    final authors =
        seedAuthors
            .where(
              (author) =>
                  book.authorIds
                      .contains(
                author.id,
              ),
            )
            .map(
              (author) =>
                  author.fullName,
            )
            .join(', ');

    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 700,
          ),
          child: Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                24,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        size: 48,
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: Text(
                          book.title,
                          style:
                              Theme.of(
                            context,
                          )
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
                    value:
                        '${book.id}',
                  ),

                  _DetailRow(
                    label: 'ISBN',
                    value:
                        book.isbn,
                  ),

                  _DetailRow(
                    label: 'Авторы',
                    value:
                        authors.isEmpty
                            ? 'Не указаны'
                            : authors,
                  ),

                  _DetailRow(
                    label: 'Жанры',
                    value:
                        genres.isEmpty
                            ? 'Не указаны'
                            : genres,
                  ),

                  _DetailRow(
                    label:
                        'Издательство',
                    value:
                        publisher,
                  ),

                  _DetailRow(
                    label:
                        'Год издания',
                    value:
                        '${book.year}',
                  ),

                  _DetailRow(
                    label:
                        'Количество страниц',
                    value:
                        '${book.pages}',
                  ),

                  _DetailRow(
                    label:
                        'Всего экземпляров',
                    value:
                        '${book.copiesTotal}',
                  ),

                  _DetailRow(
                    label: 'Доступно',
                    value:
                        '${book.copiesAvailable}',
                  ),

                  _DetailRow(
                    label: 'Статус',
                    value:
                        book.isDeleted
                            ? 'Удалена'
                            : 'Активна',
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  if (book.copiesAvailable ==
                      0)
                    Container(
                      width:
                          double.infinity,
                      margin:
                          const EdgeInsets.only(
                        bottom: 16,
                      ),
                      padding:
                          const EdgeInsets.all(
                        12,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .errorContainer,
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                      ),
                      child: Text(
                        'Свободных экземпляров '
                        'нет. При попытке выдачи '
                        'сервер должен вернуть '
                        '409 Conflict.',
                        style:
                            TextStyle(
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .onErrorContainer,
                        ),
                      ),
                    ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        FilledButton.icon(
                      onPressed:
                          issuing
                              ? null
                              : onIssue,
                      icon: issuing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .assignment_ind_outlined,
                            ),
                      label: Text(
                        issuing
                            ? 'Оформление...'
                            : 'Выдать книгу',
                      ),
                    ),
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

class _IssueBookDialog
    extends StatefulWidget {
  final Book book;
  final List<Reader> readers;

  const _IssueBookDialog({
    required this.book,
    required this.readers,
  });

  @override
  State<_IssueBookDialog>
      createState() =>
          _IssueBookDialogState();
}

class _IssueBookDialogState
    extends State<_IssueBookDialog> {
  int? _readerId;
  int _days = 14;

  @override
  void initState() {
    super.initState();

    if (widget.readers.isNotEmpty) {
      _readerId =
          widget.readers.first.id;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      title: const Text(
        'Выдача книги',
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
          children: [
            Text(
              widget.book.title,
              style: Theme.of(
                context,
              )
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Свободно экземпляров: '
              '${widget.book.copiesAvailable}',
            ),

            const SizedBox(
              height: 20,
            ),

            DropdownButtonFormField<
                int>(
              initialValue:
                  _readerId,
              decoration:
                  const InputDecoration(
                labelText:
                    'Читатель',
                border:
                    OutlineInputBorder(),
              ),
              items:
                  widget.readers
                      .map(
                (reader) {
                  return DropdownMenuItem<
                      int>(
                    value:
                        reader.id,
                    child: Text(
                      '${reader.fullName} '
                      '(${reader.email})',
                    ),
                  );
                },
              ).toList(),
              onChanged: (
                value,
              ) {
                setState(() {
                  _readerId =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 16,
            ),

            DropdownButtonFormField<
                int>(
              initialValue:
                  _days,
              decoration:
                  const InputDecoration(
                labelText:
                    'Срок выдачи',
                border:
                    OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 7,
                  child: Text(
                    '7 дней',
                  ),
                ),
                DropdownMenuItem(
                  value: 14,
                  child: Text(
                    '14 дней',
                  ),
                ),
                DropdownMenuItem(
                  value: 21,
                  child: Text(
                    '21 день',
                  ),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text(
                    '30 дней',
                  ),
                ),
              ],
              onChanged: (
                value,
              ) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _days = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
          child: const Text(
            'Отмена',
          ),
        ),
        FilledButton(
          onPressed:
              _readerId == null
                  ? null
                  : () {
                      Navigator.pop(
                        context,
                        _LoanInput(
                          readerId:
                              _readerId!,
                          days:
                              _days,
                        ),
                      );
                    },
          child: const Text(
            'Выдать',
          ),
        ),
      ],
    );
  }
}

class _LoanInput {
  final int readerId;
  final int days;

  const _LoanInput({
    required this.readerId,
    required this.days,
  });
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
            width: 180,
            child: Text(
              label,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotFoundView
    extends StatelessWidget {
  final String message;

  const _NotFoundView({
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            message,
            style:
                const TextStyle(
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}