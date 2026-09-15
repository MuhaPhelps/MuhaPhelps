import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/publisher.dart';
import '../state/publisher_list_notifier.dart';
import '../utils/validators.dart';
import '../widgets/entity_form_scaffold.dart';

class PublisherFormScreen
    extends StatefulWidget {
  final int? id;

  const PublisherFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<PublisherFormScreen>
      createState() =>
          _PublisherFormScreenState();
}

class _PublisherFormScreenState
    extends State<PublisherFormScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _cityController =
      TextEditingController();

  final _foundedYearController =
      TextEditingController();

  Future<void>? _loadFuture;

  Publisher? _originalPublisher;

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
    _cityController.dispose();
    _foundedYearController.dispose();

    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!widget.isEditing) {
      return;
    }

    final publisher = await context
        .read<PublisherListNotifier>()
        .findById(
          widget.id!,
        );

    if (publisher == null) {
      throw StateError(
        'Издательство '
        '${widget.id} не найдено',
      );
    }

    _originalPublisher =
        publisher;

    _nameController.text =
        publisher.name;

    _cityController.text =
        publisher.city;

    _foundedYearController.text =
        publisher.foundedYear
                ?.toString() ??
            '';

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

  String? _validateFoundedYear(
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
      return 'Год основания должен быть '
          'целым числом';
    }

    if (year < 1400 ||
        year >
            DateTime.now().year) {
      return 'Год основания должен быть '
          'от 1400 до ${DateTime.now().year}';
    }

    return null;
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
      context.go(
        '/publishers',
      );
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

    final foundedYearText =
        _foundedYearController
            .text
            .trim();

    final publisher = Publisher(
      id: widget.id ?? 0,
      name:
          _nameController.text.trim(),
      city:
          _cityController.text.trim(),
      foundedYear:
          foundedYearText.isEmpty
              ? null
              : int.parse(
                  foundedYearText,
                ),
      deletedAt:
          _originalPublisher
              ?.deletedAt,
    );

    try {
      final notifier =
          context.read<
              PublisherListNotifier>();

      final saved =
          widget.isEditing
              ? await notifier.update(
                  publisher,
                )
              : await notifier.create(
                  publisher,
                );

      if (!mounted) {
        return;
      }

      setState(() {
        _dirty = false;
        _saving = false;
      });

      context.go(
        '/publishers/${saved.id}',
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
            'Не удалось сохранить '
            'издательство: $e',
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
                    ? 'Редактирование издательства'
                    : 'Новое издательство',
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
              ? 'Редактирование издательства'
              : 'Создание издательства',
          heading: widget.isEditing
              ? 'Изменение данных издательства'
              : 'Добавление нового издательства',
          saveLabel: widget.isEditing
              ? 'Сохранить изменения'
              : 'Создать издательство',
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
                      maxLength: 150,
                    );
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                TextFormField(
                  controller:
                      _cityController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Город *',
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
                          'Город',
                      maxLength: 100,
                    );
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                TextFormField(
                  controller:
                      _foundedYearController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Год основания',
                    hintText:
                        'Например: 1991',
                    border:
                        OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    _markDirty();
                  },
                  validator:
                      _validateFoundedYear,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}