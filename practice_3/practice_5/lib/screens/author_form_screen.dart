import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../state/author_list_notifier.dart';
import '../utils/validators.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? id;

  const AuthorFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<AuthorFormScreen> createState() =>
      _AuthorFormScreenState();
}

class _AuthorFormScreenState
    extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController =
      TextEditingController();

  final _birthYearController =
      TextEditingController();

  final _countryController =
      TextEditingController();

  Future<void>? _loadFuture;

  Author? _originalAuthor;

  bool _dirty = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _loadFuture ??=
        _loadInitialData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthYearController.dispose();
    _countryController.dispose();

    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!widget.isEditing) {
      return;
    }

    final notifier =
        context.read<AuthorListNotifier>();

    final author =
        await notifier.findById(
      widget.id!,
    );

    if (!mounted) {
      return;
    }

    if (author == null) {
      throw StateError(
        'Автор ${widget.id} не найден',
      );
    }

    _originalAuthor = author;

    _fullNameController.text =
        author.fullName;

    _birthYearController.text =
        author.birthYear?.toString() ?? '';

    _countryController.text =
        author.country;

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

  Future<bool> _confirmDiscard() async {
    if (!_dirty) {
      return true;
    }

    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
      context.go('/authors');
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

  String? _validateBirthYear(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return null;
    }

    final year =
        int.tryParse(
      value.trim(),
    );

    if (year == null) {
      return 'Год рождения должен быть целым числом';
    }

    if (year < 1 ||
        year > DateTime.now().year) {
      return 'Год рождения должен быть '
          'от 1 до ${DateTime.now().year}';
    }

    return null;
  }

  Future<void> _save() async {
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

    final birthYearText =
        _birthYearController
            .text
            .trim();

    final author = Author(
      id: widget.id ?? 0,
      fullName:
          _fullNameController
              .text
              .trim(),
      birthYear:
          birthYearText.isEmpty
              ? null
              : int.parse(
                  birthYearText,
                ),
      country:
          _countryController
              .text
              .trim(),
      deletedAt:
          _originalAuthor
              ?.deletedAt,
    );

    try {
      final notifier =
          context.read<
              AuthorListNotifier>();

      final Author saved;

      if (widget.isEditing) {
        saved =
            await notifier.update(
          author,
        );
      } else {
        saved =
            await notifier.create(
          author,
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
        '/authors/${saved.id}',
      );
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
            'Не удалось сохранить автора: $e',
          ),
        ),
      );
    }
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
                    ? 'Редактирование автора'
                    : 'Новый автор',
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
                    ? 'Редактирование автора'
                    : 'Создание автора',
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
                    maxWidth: 700,
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
                              ? 'Изменение данных автора'
                              : 'Добавление нового автора',
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
                              _fullNameController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'ФИО *',
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
                                  'ФИО',
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
                              _birthYearController,
                          keyboardType:
                              TextInputType
                                  .number,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Год рождения',
                            border:
                                OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            _markDirty();
                          },
                          validator:
                              _validateBirthYear,
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        TextFormField(
                          controller:
                              _countryController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Страна *',
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
                                  'Страна',
                              maxLength:
                                  100,
                            );
                          },
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
                                  _saving
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
                                      Icons
                                          .save,
                                    ),
                              label: Text(
                                widget
                                        .isEditing
                                    ? 'Сохранить изменения'
                                    : 'Создать автора',
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