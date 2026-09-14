import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../repositories/book_repository.dart';
import '../state/author_list_notifier.dart';
import '../state/book_list_notifier.dart';
import '../state/genre_list_notifier.dart';
import '../state/publisher_list_notifier.dart';
import '../utils/validators.dart';

class BookFormScreen
    extends StatefulWidget {
  final int? id;

  const BookFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<BookFormScreen>
      createState() =>
          _BookFormScreenState();
}

class _BookFormScreenState
    extends State<BookFormScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _titleController =
      TextEditingController();

  final _isbnController =
      TextEditingController();

  final _yearController =
      TextEditingController();

  final _pagesController =
      TextEditingController();

  final _copiesTotalController =
      TextEditingController();

  final _copiesAvailableController =
      TextEditingController();

  Future<void>? _loadFuture;

  Book? _originalBook;

  List<Author> _allAuthors = [];
  List<Genre> _allGenres = [];
  List<Publisher> _publishers = [];

  List<Author> _visibleAuthors = [];
  List<Genre> _visibleGenres = [];

  int? _publisherId;

  List<int> _authorIds = [];
  List<int> _genreIds = [];

  bool _dirty = false;
  bool _saving = false;

  bool _loadingRelations = false;
  bool _showAllRelations = false;

  String? _relationHint;
  String? _isbnUniqueError;

  int _relationRequestId = 0;
  int _relationRevision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _loadFuture ??=
        _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _copiesTotalController.dispose();
    _copiesAvailableController.dispose();

    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final authorNotifier =
        context.read<
            AuthorListNotifier>();

    final genreNotifier =
        context.read<
            GenreListNotifier>();

    final publisherNotifier =
        context.read<
            PublisherListNotifier>();

    final bookNotifier =
        context.read<
            BookListNotifier>();

    await authorNotifier.applyQuery(
      const AuthorQuery(
        size: 50,
      ),
    );

    await genreNotifier.applyQuery(
      const GenreQuery(
        size: 50,
      ),
    );

    await publisherNotifier.applyQuery(
      const PublisherQuery(
        size: 50,
      ),
    );

    if (!mounted) {
      return;
    }

    _allAuthors = [
      ...authorNotifier.result.items,
    ];

    _allGenres = [
      ...genreNotifier.result.items,
    ];

    _publishers = [
      ...publisherNotifier.result.items,
    ];

    _allAuthors.sort(
      (a, b) =>
          a.fullName.compareTo(
        b.fullName,
      ),
    );

    _allGenres.sort(
      (a, b) => a.name.compareTo(
        b.name,
      ),
    );

    _publishers.sort(
      (a, b) =>
          a.name.compareTo(
        b.name,
      ),
    );

    _visibleAuthors = [
      ..._allAuthors,
    ];

    _visibleGenres = [
      ..._allGenres,
    ];

    if (!widget.isEditing) {
      _dirty = false;
      return;
    }

    final book =
        await bookNotifier.findById(
      widget.id!,
    );

    if (!mounted) {
      return;
    }

    if (book == null) {
      throw StateError(
        'Книга ${widget.id} не найдена',
      );
    }

    _originalBook = book;

    _titleController.text =
        book.title;

    _isbnController.text =
        book.isbn;

    _yearController.text =
        '${book.year}';

    _pagesController.text =
        '${book.pages}';

    _copiesTotalController.text =
        '${book.copiesTotal}';

    _copiesAvailableController.text =
        '${book.copiesAvailable}';

    _publisherId =
        book.publisherId;

    _authorIds = [
      ...book.authorIds,
    ];

    _genreIds = [
      ...book.genreIds,
    ];

    await _refreshRelationOptions(
      _publisherId,
      notify: false,
    );

    _dirty = false;
  }

  void _markDirty() {
    if (_dirty) {
      return;
    }

    setState(() {
      _dirty = true;
    });
  }

  void _onIsbnChanged(
    String value,
  ) {
    if (_isbnUniqueError != null) {
      setState(() {
        _isbnUniqueError = null;
        _dirty = true;
      });
    } else {
      _markDirty();
    }
  }

  Future<void> _refreshRelationOptions(
    int? publisherId, {
    bool notify = true,
  }) async {
    final requestId =
        ++_relationRequestId;

    if (publisherId == null ||
        _showAllRelations) {
      if (notify && mounted) {
        setState(() {
          _visibleAuthors = [
            ..._allAuthors,
          ];

          _visibleGenres = [
            ..._allGenres,
          ];

          _relationHint = null;
          _loadingRelations = false;
          _relationRevision++;
        });
      } else {
        _visibleAuthors = [
          ..._allAuthors,
        ];

        _visibleGenres = [
          ..._allGenres,
        ];

        _relationHint = null;
        _loadingRelations = false;
        _relationRevision++;
      }

      return;
    }

    if (notify && mounted) {
      setState(() {
        _loadingRelations = true;
      });
    } else {
      _loadingRelations = true;
    }

    final bookRepository =
        context.read<BookRepository>();

    try {
      final result =
          await bookRepository.find(
        BookQuery(
          publisherId:
              publisherId,
          page: 1,
          size: 50,
          includeDeleted:
              false,
        ),
      );

      if (!mounted) {
        return;
      }

      if (requestId !=
          _relationRequestId) {
        return;
      }

      final authorIds =
          <int>{};

      final genreIds =
          <int>{};

      for (final book
          in result.items) {
        authorIds.addAll(
          book.authorIds,
        );

        genreIds.addAll(
          book.genreIds,
        );
      }

      List<Author> nextAuthors;
      List<Genre> nextGenres;
      String hint;

      if (result.items.isEmpty ||
          authorIds.isEmpty ||
          genreIds.isEmpty) {
        nextAuthors = [
          ..._allAuthors,
        ];

        nextGenres = [
          ..._allGenres,
        ];

        hint =
            'Для выбранного издательства '
            'пока недостаточно связанных '
            'данных, поэтому доступны все '
            'авторы и жанры.';
      } else {
        nextAuthors =
            _allAuthors
                .where(
                  (author) =>
                      authorIds.contains(
                    author.id,
                  ),
                )
                .toList();

        nextGenres =
            _allGenres
                .where(
                  (genre) =>
                      genreIds.contains(
                    genre.id,
                  ),
                )
                .toList();

        final allowedAuthorIds =
            nextAuthors
                .map(
                  (author) =>
                      author.id,
                )
                .toSet();

        final allowedGenreIds =
            nextGenres
                .map(
                  (genre) =>
                      genre.id,
                )
                .toSet();

        _authorIds = _authorIds
            .where(
              allowedAuthorIds
                  .contains,
            )
            .toList();

        _genreIds = _genreIds
            .where(
              allowedGenreIds
                  .contains,
            )
            .toList();

        hint =
            'Каскадный фильтр: найдено '
            '${nextAuthors.length} '
            'авторов и '
            '${nextGenres.length} '
            'жанров, связанных с книгами '
            'выбранного издательства.';
      }

      if (notify) {
        setState(() {
          _visibleAuthors =
              nextAuthors;

          _visibleGenres =
              nextGenres;

          _relationHint =
              hint;

          _loadingRelations =
              false;

          _relationRevision++;
        });
      } else {
        _visibleAuthors =
            nextAuthors;

        _visibleGenres =
            nextGenres;

        _relationHint =
            hint;

        _loadingRelations =
            false;

        _relationRevision++;
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      if (notify) {
        setState(() {
          _visibleAuthors = [
            ..._allAuthors,
          ];

          _visibleGenres = [
            ..._allGenres,
          ];

          _relationHint =
              'Не удалось применить '
              'каскадный фильтр. '
              'Показаны все варианты.';

          _loadingRelations =
              false;

          _relationRevision++;
        });
      } else {
        _visibleAuthors = [
          ..._allAuthors,
        ];

        _visibleGenres = [
          ..._allGenres,
        ];

        _relationHint =
            'Не удалось применить '
            'каскадный фильтр. '
            'Показаны все варианты.';

        _loadingRelations =
            false;

        _relationRevision++;
      }
    }
  }

  Future<void> _setShowAllRelations(
    bool value,
  ) async {
    setState(() {
      _showAllRelations =
          value;
    });

    if (value) {
      setState(() {
        _visibleAuthors = [
          ..._allAuthors,
        ];

        _visibleGenres = [
          ..._allGenres,
        ];

        _relationHint =
            'Каскадный фильтр временно '
            'отключён — показаны все '
            'авторы и жанры.';

        _relationRevision++;
      });

      return;
    }

    await _refreshRelationOptions(
      _publisherId,
    );
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) {
      return true;
    }

    final result =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Несохранённые изменения',
          ),
          content: const Text(
            'Изменения не сохранены. '
            'Покинуть страницу?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Остаться',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Выйти',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _leaveWithoutPrompt() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _dirty = false;
    });

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        '/books',
      );
    }
  }

  Future<void> _goBack() async {
    final canLeave =
        await _confirmDiscard();

    if (!mounted ||
        !canLeave) {
      return;
    }

    await _leaveWithoutPrompt();
  }

  String? _validateCopiesAvailable(
    String? value,
  ) {
    final baseError =
        AppValidators
            .nonNegativeInteger(
      value,
      fieldName:
          'Доступное количество',
    );

    if (baseError != null) {
      return baseError;
    }

    final available =
        int.parse(
      value!.trim(),
    );

    final total =
        int.tryParse(
      _copiesTotalController.text
          .trim(),
    );

    if (total != null &&
        available > total) {
      return 'Доступное количество '
          'не может быть больше общего';
    }

    return null;
  }

  Future<void> _save() async {
    setState(() {
      _isbnUniqueError = null;
    });

    final valid =
        _formKey.currentState
                ?.validate() ??
            false;

    if (!valid) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final book = Book(
      id: widget.id ?? 0,
      title:
          _titleController
              .text
              .trim(),
      isbn:
          _isbnController
              .text
              .trim(),
      year: int.parse(
        _yearController.text
            .trim(),
      ),
      pages: int.parse(
        _pagesController.text
            .trim(),
      ),
      publisherId:
          _publisherId!,
      authorIds: [
        ..._authorIds,
      ],
      genreIds: [
        ..._genreIds,
      ],
      copiesTotal:
          int.parse(
        _copiesTotalController
            .text
            .trim(),
      ),
      copiesAvailable:
          int.parse(
        _copiesAvailableController
            .text
            .trim(),
      ),
      deletedAt:
          _originalBook
              ?.deletedAt,
    );

    try {
      final notifier =
          context.read<
              BookListNotifier>();

      final Book saved;

      if (widget.isEditing) {
        saved =
            await notifier.update(
          book,
        );
      } else {
        saved =
            await notifier.create(
          book,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _dirty = false;
        _saving = false;
      });

      context.go(
        '/books/${saved.id}',
      );
    } on BookIsbnExistsException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isbnUniqueError =
            'Книга с таким ISBN '
            'уже существует';

        _saving = false;
      });

      _formKey.currentState
          ?.validate();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось сохранить '
            'книгу: $e',
          ),
        ),
      );
    }
  }

  Widget _buildMultiSelect<T>({
    required String fieldKey,
    required String label,
    required List<T> items,
    required List<int> selectedIds,
    required int Function(T item)
        idOf,
    required String Function(T item)
        labelOf,
    required void Function(
      List<int> values,
    )
    onChanged,
    required String errorText,
  }) {
    return FormField<List<int>>(
      key: ValueKey(
        fieldKey,
      ),
      initialValue: [
        ...selectedIds,
      ],
      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return errorText;
        }

        return null;
      },
      builder: (field) {
        final selected =
            field.value ??
                <int>[];

        return InputDecorator(
          decoration:
              InputDecoration(
            labelText: label,
            border:
                const OutlineInputBorder(),
            errorText:
                field.errorText,
          ),
          child: items.isEmpty
              ? const Text(
                  'Нет доступных вариантов',
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      items.map(
                    (item) {
                      final id =
                          idOf(item);

                      final isSelected =
                          selected.contains(
                        id,
                      );

                      return FilterChip(
                        label: Text(
                          labelOf(
                            item,
                          ),
                        ),
                        selected:
                            isSelected,
                        onSelected:
                            (_) {
                          final next = [
                            ...selected,
                          ];

                          if (isSelected) {
                            next.remove(
                              id,
                            );
                          } else {
                            next.add(
                              id,
                            );
                          }

                          field.didChange(
                            next,
                          );

                          onChanged(
                            next,
                          );

                          _markDirty();
                        },
                      );
                    },
                  ).toList(),
                ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (
        buildContext,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.isEditing
                    ? 'Редактирование книги'
                    : 'Новая книга',
              ),
            ),
            body: const Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Ошибка',
              ),
            ),
            body: Center(
              child: Text(
                'Не удалось открыть форму:\n'
                '${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            ),
          );
        }

        return PopScope(
          canPop: !_dirty,
          onPopInvokedWithResult: (
            didPop,
            result,
          ) async {
            if (didPop) {
              return;
            }

            final canLeave =
                await _confirmDiscard();

            if (!mounted ||
                !canLeave) {
              return;
            }

            await _leaveWithoutPrompt();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Назад',
                onPressed: _goBack,
                icon: const Icon(
                  Icons.arrow_back,
                ),
              ),
              title: Text(
                widget.isEditing
                    ? 'Редактирование книги'
                    : 'Создание книги',
              ),
            ),
            body:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 850,
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode:
                        AutovalidateMode
                            .onUserInteraction,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,
                      children: [
                        Text(
                          widget.isEditing
                              ? 'Изменение данных книги'
                              : 'Добавление новой книги',
                          style: Theme.of(
                            buildContext,
                          )
                              .textTheme
                              .headlineSmall,
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        TextFormField(
                          controller:
                              _titleController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Название *',
                            border:
                                OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            _markDirty();
                          },
                          validator:
                              (value) {
                            return AppValidators
                                .requiredWithMaxLength(
                              value,
                              fieldName:
                                  'Название',
                              maxLength:
                                  200,
                            );
                          },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        TextFormField(
                          controller:
                              _isbnController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'ISBN *',
                            border:
                                OutlineInputBorder(),
                          ),
                          onChanged:
                              _onIsbnChanged,
                          validator:
                              (value) {
                            final error =
                                AppValidators
                                    .requiredWithMaxLength(
                              value,
                              fieldName:
                                  'ISBN',
                              maxLength:
                                  50,
                            );

                            if (error !=
                                null) {
                              return error;
                            }

                            return _isbnUniqueError;
                          },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Expanded(
                              child:
                                  TextFormField(
                                controller:
                                    _yearController,
                                keyboardType:
                                    TextInputType
                                        .number,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Год издания *',
                                  border:
                                      OutlineInputBorder(),
                                ),
                                onChanged:
                                    (_) {
                                  _markDirty();
                                },
                                validator:
                                    (value) {
                                  return AppValidators
                                      .integerInRange(
                                    value,
                                    fieldName:
                                        'Год издания',
                                    min:
                                        1450,
                                    max:
                                        DateTime.now()
                                            .year,
                                  );
                                },
                              ),
                            ),

                            const SizedBox(
                              width: 16,
                            ),

                            Expanded(
                              child:
                                  TextFormField(
                                controller:
                                    _pagesController,
                                keyboardType:
                                    TextInputType
                                        .number,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Количество страниц *',
                                  border:
                                      OutlineInputBorder(),
                                ),
                                onChanged:
                                    (_) {
                                  _markDirty();
                                },
                                validator:
                                    (value) {
                                  return AppValidators
                                      .positiveInteger(
                                    value,
                                    fieldName:
                                        'Количество страниц',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        DropdownButtonFormField<
                            int>(
                          initialValue:
                              _publisherId,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Издательство *',
                            border:
                                OutlineInputBorder(),
                          ),
                          items:
                              _publishers
                                  .map(
                            (publisher) {
                              return DropdownMenuItem<
                                  int>(
                                value:
                                    publisher.id,
                                child: Text(
                                  publisher.name,
                                ),
                              );
                            },
                          ).toList(),
                          onChanged:
                              (value) async {
                            setState(() {
                              _publisherId =
                                  value;

                              _showAllRelations =
                                  false;

                              _dirty =
                                  true;
                            });

                            await _refreshRelationOptions(
                              value,
                            );
                          },
                          validator:
                              (value) {
                            if (value ==
                                null) {
                              return 'Выберите издательство';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        if (_publisherId !=
                            null)
                          Card(
                            margin:
                                EdgeInsets.zero,
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .filter_alt_outlined,
                                      ),

                                      const SizedBox(
                                        width: 8,
                                      ),

                                      const Expanded(
                                        child: Text(
                                          'Каскадный выбор',
                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      FilterChip(
                                        label:
                                            const Text(
                                          'Показать все варианты',
                                        ),
                                        selected:
                                            _showAllRelations,
                                        onSelected:
                                            _loadingRelations
                                                ? null
                                                : _setShowAllRelations,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  if (_loadingRelations)
                                    const Row(
                                      children: [
                                        SizedBox(
                                          width:
                                              18,
                                          height:
                                              18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                          ),
                                        ),
                                        SizedBox(
                                          width:
                                              12,
                                        ),
                                        Text(
                                          'Подбираем связанные '
                                          'варианты...',
                                        ),
                                      ],
                                    )
                                  else if (_relationHint !=
                                      null)
                                    Text(
                                      _relationHint!,
                                    ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(
                          height: 16,
                        ),

                        if (_loadingRelations)
                          const Center(
                            child:
                                Padding(
                              padding:
                                  EdgeInsets.all(
                                24,
                              ),
                              child:
                                  CircularProgressIndicator(),
                            ),
                          )
                        else ...[
                          _buildMultiSelect<
                              Author>(
                            fieldKey:
                                'authors-'
                                '$_relationRevision',
                            label:
                                'Авторы *',
                            items:
                                _visibleAuthors,
                            selectedIds:
                                _authorIds,
                            idOf:
                                (author) =>
                                    author.id,
                            labelOf:
                                (author) =>
                                    author
                                        .fullName,
                            onChanged:
                                (values) {
                              _authorIds = [
                                ...values,
                              ];
                            },
                            errorText:
                                'Выберите хотя бы одного автора',
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          _buildMultiSelect<
                              Genre>(
                            fieldKey:
                                'genres-'
                                '$_relationRevision',
                            label:
                                'Жанры *',
                            items:
                                _visibleGenres,
                            selectedIds:
                                _genreIds,
                            idOf:
                                (genre) =>
                                    genre.id,
                            labelOf:
                                (genre) =>
                                    genre.name,
                            onChanged:
                                (values) {
                              _genreIds = [
                                ...values,
                              ];
                            },
                            errorText:
                                'Выберите хотя бы один жанр',
                          ),
                        ],

                        const SizedBox(
                          height: 16,
                        ),

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Expanded(
                              child:
                                  TextFormField(
                                controller:
                                    _copiesTotalController,
                                keyboardType:
                                    TextInputType
                                        .number,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Всего экземпляров *',
                                  border:
                                      OutlineInputBorder(),
                                ),
                                onChanged:
                                    (_) {
                                  _markDirty();
                                },
                                validator:
                                    (value) {
                                  return AppValidators
                                      .positiveInteger(
                                    value,
                                    fieldName:
                                        'Количество экземпляров',
                                  );
                                },
                              ),
                            ),

                            const SizedBox(
                              width: 16,
                            ),

                            Expanded(
                              child:
                                  TextFormField(
                                controller:
                                    _copiesAvailableController,
                                keyboardType:
                                    TextInputType
                                        .number,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Доступно *',
                                  border:
                                      OutlineInputBorder(),
                                ),
                                onChanged:
                                    (_) {
                                  _markDirty();

                                  _formKey
                                      .currentState
                                      ?.validate();
                                },
                                validator:
                                    _validateCopiesAvailable,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 32,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .end,
                          children: [
                            TextButton(
                              onPressed:
                                  _saving
                                      ? null
                                      : _goBack,
                              child:
                                  const Text(
                                'Отмена',
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            FilledButton.icon(
                              onPressed:
                                  _saving ||
                                          _loadingRelations
                                      ? null
                                      : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width:
                                          18,
                                      height:
                                          18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.save,
                                    ),
                              label: Text(
                                widget
                                        .isEditing
                                    ? 'Сохранить изменения'
                                    : 'Создать книгу',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}