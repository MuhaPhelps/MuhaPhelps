import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/genre.dart';
import '../state/genre_list_notifier.dart';
import '../utils/validators.dart';
import '../widgets/entity_form_scaffold.dart';

class GenreFormScreen
    extends StatefulWidget {
  final int? id;

  const GenreFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<GenreFormScreen>
      createState() =>
          _GenreFormScreenState();
}

class _GenreFormScreenState
    extends State<GenreFormScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  Future<void>? _loadFuture;

  Genre? _originalGenre;

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
    _nameController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!widget.isEditing) {
      return;
    }

    final genre = await context
        .read<GenreListNotifier>()
        .findById(
          widget.id!,
        );

    if (genre == null) {
      throw StateError(
        'Жанр ${widget.id} не найден',
      );
    }

    _originalGenre = genre;

    _nameController.text =
        genre.name;

    _descriptionController.text =
        genre.description;

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

  Future<void> _leave() async {
    if (mounted) {
      setState(() {
        _dirty = false;
      });
    }

    if (!mounted) {
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/genres');
    }
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

    final genre = Genre(
      id: widget.id ?? 0,
      name:
          _nameController.text.trim(),
      description:
          _descriptionController
              .text
              .trim(),
      deletedAt:
          _originalGenre?.deletedAt,
    );

    try {
      final notifier =
          context.read<
              GenreListNotifier>();

      final saved =
          widget.isEditing
              ? await notifier.update(
                  genre,
                )
              : await notifier.create(
                  genre,
                );

      if (!mounted) {
        return;
      }

      setState(() {
        _dirty = false;
        _saving = false;
      });

      context.go(
        '/genres/${saved.id}',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось сохранить жанр: $e',
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
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.isEditing
                    ? 'Редактирование жанра'
                    : 'Новый жанр',
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

        return EntityFormScaffold(
          title: widget.isEditing
              ? 'Редактирование жанра'
              : 'Создание жанра',
          heading: widget.isEditing
              ? 'Изменение данных жанра'
              : 'Добавление нового жанра',
          saveLabel: widget.isEditing
              ? 'Сохранить изменения'
              : 'Создать жанр',
          isDirty: _dirty,
          isSaving: _saving,
          onSave: _save,
          onExitConfirmed: _leave,
          child: Form(
            key: _formKey,
            autovalidateMode:
                AutovalidateMode
                    .onUserInteraction,
            child: Column(
              children: [
                TextFormField(
                  controller:
                      _nameController,
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
                  validator: (value) {
                    return AppValidators
                        .requiredWithMaxLength(
                      value,
                      fieldName:
                          'Название',
                      maxLength: 100,
                    );
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                TextFormField(
                  controller:
                      _descriptionController,
                  minLines: 3,
                  maxLines: 6,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Описание *',
                    alignLabelWithHint:
                        true,
                    border:
                        OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    _markDirty();
                  },
                  validator: (value) {
                    return AppValidators
                        .requiredWithMaxLength(
                      value,
                      fieldName:
                          'Описание',
                      maxLength: 500,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}