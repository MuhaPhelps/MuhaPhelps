import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/library_card.dart';
import '../models/reader.dart';
import '../repositories/reader_repository.dart';
import '../state/reader_list_notifier.dart';
import '../utils/validators.dart';
import '../widgets/entity_form_scaffold.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? id;

  const ReaderFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<ReaderFormScreen> createState() =>
      _ReaderFormScreenState();
}

class _ReaderFormScreenState
    extends State<ReaderFormScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _fullNameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _cardNumberController =
      TextEditingController();

  Future<void>? _loadFuture;

  Reader? _originalReader;

  DateTime? _issuedAt;
  DateTime? _expiresAt;

  bool _dirty = false;
  bool _saving = false;

  String? _emailUniqueError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _loadFuture ??=
        _loadInitialData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();

    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!widget.isEditing) {
      return;
    }

    final reader = await context
        .read<ReaderListNotifier>()
        .findById(widget.id!);

    if (reader == null) {
      throw StateError(
        'Читатель ${widget.id} не найден',
      );
    }

    _originalReader = reader;

    _fullNameController.text =
        reader.fullName;

    _emailController.text =
        reader.email;

    _phoneController.text =
        reader.phone;

    _cardNumberController.text =
        reader.card.number;

    _issuedAt =
        reader.card.issuedAt;

    _expiresAt =
        reader.card.expiresAt;

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

  void _onEmailChanged(
    String value,
  ) {
    if (_emailUniqueError != null) {
      setState(() {
        _emailUniqueError = null;
        _dirty = true;
      });
    } else {
      _markDirty();
    }
  }

  String _formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Не выбрана';
    }

    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  Future<DateTime?> _selectDate({
    required DateTime? current,
    required String title,
  }) async {
    final now = DateTime.now();

    return showDatePicker(
      context: context,
      helpText: title,
      initialDate:
          current ?? now,
      firstDate:
          DateTime(1900),
      lastDate:
          DateTime(2100),
    );
  }

  String? _validatePhone(
    String? value,
  ) {
    final requiredError =
        AppValidators.requiredText(
      value,
      fieldName: 'Телефон',
    );

    if (requiredError != null) {
      return requiredError;
    }

    final text =
        value!.trim();

    if (text.length < 7 ||
        text.length > 25) {
      return 'Телефон должен содержать '
          'от 7 до 25 символов';
    }

    final expression =
        RegExp(
      r'^[0-9+\-() ]+$',
    );

    if (!expression.hasMatch(text)) {
      return 'Телефон содержит '
          'недопустимые символы';
    }

    return null;
  }

  String? _validateExpiry(
    DateTime? value,
  ) {
    if (value == null) {
      return 'Выберите срок действия билета';
    }

    if (_issuedAt != null) {
      final issued = DateTime(
        _issuedAt!.year,
        _issuedAt!.month,
        _issuedAt!.day,
      );

      final expires = DateTime(
        value.year,
        value.month,
        value.day,
      );

      if (expires.isBefore(
        issued,
      )) {
        return 'Срок действия не может '
            'быть раньше даты выдачи';
      }
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
        '/readers',
      );
    }
  }

  Future<void> _save() async {
    setState(() {
      _emailUniqueError = null;
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

    final card = LibraryCard(
      id:
          _originalReader
              ?.card
              .id ??
          0,
      number:
          _cardNumberController
              .text
              .trim(),
      issuedAt:
          _issuedAt,
      expiresAt:
          _expiresAt,
    );

    final reader = Reader(
      id: widget.id ?? 0,
      fullName:
          _fullNameController
              .text
              .trim(),
      email:
          _emailController
              .text
              .trim(),
      phone:
          _phoneController
              .text
              .trim(),
      card: card,
      deletedAt:
          _originalReader
              ?.deletedAt,
    );

    try {
      final notifier =
          context.read<
              ReaderListNotifier>();

      final saved =
          widget.isEditing
              ? await notifier.update(
                  reader,
                )
              : await notifier.create(
                  reader,
                );

      if (!mounted) {
        return;
      }

      setState(() {
        _dirty = false;
        _saving = false;
      });

      context.go(
        '/readers/${saved.id}',
      );
    } on ReaderEmailExistsException {
      if (!mounted) {
        return;
      }

      setState(() {
        _emailUniqueError =
            'Читатель с таким email '
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
            'читателя: $e',
          ),
        ),
      );
    }
  }

  Widget _buildIssuedDateField() {
    return FormField<DateTime>(
      initialValue: _issuedAt,
      validator: (value) {
        if (value == null) {
          return 'Выберите дату выдачи билета';
        }

        return null;
      },
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText:
                'Дата выдачи *',
            border:
                const OutlineInputBorder(),
            errorText:
                field.errorText,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 20,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  _formatDate(
                    field.value,
                  ),
                ),
              ),

              TextButton(
                onPressed:
                    _saving
                        ? null
                        : () async {
                            final selected =
                                await _selectDate(
                              current:
                                  field.value,
                              title:
                                  'Дата выдачи билета',
                            );

                            if (selected ==
                                null) {
                              return;
                            }

                            field.didChange(
                              selected,
                            );

                            setState(() {
                              _issuedAt =
                                  selected;
                              _dirty =
                                  true;
                            });
                          },
                child: const Text(
                  'Выбрать',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpiryDateField() {
    return FormField<DateTime>(
      initialValue: _expiresAt,
      validator:
          _validateExpiry,
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText:
                'Действителен до *',
            border:
                const OutlineInputBorder(),
            errorText:
                field.errorText,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_available,
                size: 20,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  _formatDate(
                    field.value,
                  ),
                ),
              ),

              TextButton(
                onPressed:
                    _saving
                        ? null
                        : () async {
                            final selected =
                                await _selectDate(
                              current:
                                  field.value ??
                                      _issuedAt,
                              title:
                                  'Срок действия билета',
                            );

                            if (selected ==
                                null) {
                              return;
                            }

                            field.didChange(
                              selected,
                            );

                            setState(() {
                              _expiresAt =
                                  selected;
                              _dirty =
                                  true;
                            });
                          },
                child: const Text(
                  'Выбрать',
                ),
              ),
            ],
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
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.isEditing
                    ? 'Редактирование читателя'
                    : 'Новый читатель',
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
              ? 'Редактирование читателя'
              : 'Создание читателя',
          heading: widget.isEditing
              ? 'Изменение данных читателя'
              : 'Добавление нового читателя',
          saveLabel: widget.isEditing
              ? 'Сохранить изменения'
              : 'Создать читателя',
          isDirty: _dirty,
          isSaving: _saving,
          onSave: _save,
          onExitConfirmed:
              _leave,
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
                const Text(
                  'Данные читателя',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 16,
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
                  validator: (value) {
                    return AppValidators
                        .requiredWithMaxLength(
                      value,
                      fieldName:
                          'ФИО',
                      maxLength: 200,
                    );
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                TextFormField(
                  controller:
                      _emailController,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Email *',
                    border:
                        OutlineInputBorder(),
                  ),
                  onChanged:
                      _onEmailChanged,
                  validator: (value) {
                    final error =
                        AppValidators.email(
                      value,
                    );

                    if (error != null) {
                      return error;
                    }

                    return _emailUniqueError;
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                TextFormField(
                  controller:
                      _phoneController,
                  keyboardType:
                      TextInputType.phone,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Телефон *',
                    hintText:
                        '+7 999 123-45-67',
                    border:
                        OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    _markDirty();
                  },
                  validator:
                      _validatePhone,
                ),

                const Divider(
                  height: 48,
                ),

                const Text(
                  'Читательский билет',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Билет хранится как вложенная '
                  'сущность LibraryCard читателя.',
                ),

                const SizedBox(
                  height: 16,
                ),

                TextFormField(
                  controller:
                      _cardNumberController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Номер билета *',
                    hintText:
                        'RC-000011',
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
                          'Номер билета',
                      maxLength: 50,
                    );
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                _buildIssuedDateField(),

                const SizedBox(
                  height: 16,
                ),

                _buildExpiryDateField(),
              ],
            ),
          ),
        );
      },
    );
  }
}