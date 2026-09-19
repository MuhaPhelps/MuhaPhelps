import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../models/entity_schema.dart';
import '../repositories/entity_repository.dart';
import '../widgets/entity_value.dart';
import '../widgets/page_header.dart';

class EntityFormScreen extends StatefulWidget {
  final String collection;
  final String? id;

  const EntityFormScreen({
    super.key,
    required this.collection,
    this.id,
  });

  bool get editing => id != null;

  @override
  State<EntityFormScreen> createState() => _EntityFormScreenState();
}

class _EntityFormScreenState extends State<EntityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late EntitySchema schema;
  final Map<String, TextEditingController> controllers = {};
  final Map<String, dynamic> values = {};
  final Map<String, List<Map<String, dynamic>>> relationOptions = {};
  Map<String, String> serverErrors = {};
  bool loading = true;
  bool saving = false;
  String? loadError;
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    schema = schemaByName(widget.collection);
    for (final field in schema.fields) {
      if (field.type == FieldType.text ||
          field.type == FieldType.longText ||
          field.type == FieldType.number ||
          field.type == FieldType.email ||
          field.type == FieldType.date) {
        controllers[field.name] = TextEditingController();
      }
    }
    _load();
  }

  Future<void> _load() async {
    final repository = context.read<EntityRepository>();
    try {
      for (final field in schema.relationFields) {
        relationOptions[field.name] =
            await repository.getOptions(field.relationCollection!);
      }

      if (widget.editing) {
        final record = await repository.getOne(schema, widget.id!);
        _fillFromRecord(record);
      }
    } catch (error) {
      loadError = '$error';
    }
    if (mounted) {
      setState(() => loading = false);
    }
  }

  void _fillFromRecord(Map<String, dynamic> record) {
    for (final field in schema.fields) {
      final value = record[field.name];
      if (controllers.containsKey(field.name)) {
        var text = value?.toString() ?? '';
        if (field.type == FieldType.date && text.length >= 10) {
          text = text.substring(0, 10);
        }
        controllers[field.name]!.text = text;
      } else if (field.type == FieldType.relation && field.multiple) {
        values[field.name] = value is List
            ? value.map((item) => '$item').toSet()
            : <String>{};
      } else {
        values[field.name] = value?.toString();
      }
    }
  }

  String? _validateText(FieldSchema field, String? raw) {
    final value = raw?.trim() ?? '';
    if (field.required && value.isEmpty) {
      return 'Поле обязательно';
    }
    if (value.isNotEmpty && field.minLength != null && value.length < field.minLength!) {
      return 'Минимум ${field.minLength} символа';
    }
    if (value.isNotEmpty && field.maxLength != null && value.length > field.maxLength!) {
      return 'Максимум ${field.maxLength} символов';
    }
    if (field.type == FieldType.email && value.isNotEmpty) {
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
        return 'Некорректный e-mail';
      }
    }
    if (field.type == FieldType.number && value.isNotEmpty) {
      final number = double.tryParse(value.replaceAll(',', '.'));
      if (number == null) return 'Введите число';
      if (field.min != null && number < field.min!) {
        return 'Минимум ${field.min}';
      }
      if (field.max != null && number > field.max!) {
        return 'Максимум ${field.max}';
      }
    }
    if (field.type == FieldType.date && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
        return 'Формат: ГГГГ-ММ-ДД';
      }
    }
    return serverErrors[field.name];
  }

  Widget _field(FieldSchema field) {
    if (field.type == FieldType.select) {
      return DropdownButtonFormField<String>(
        initialValue: values[field.name] as String?,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        items: field.options.entries
            .map(
              (entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
        validator: (value) {
          if (field.required && (value == null || value.isEmpty)) {
            return 'Выберите значение';
          }
          return serverErrors[field.name];
        },
        onChanged: (value) {
          setState(() {
            values[field.name] = value;
            serverErrors.remove(field.name);
          });
        },
      );
    }

    if (field.type == FieldType.relation && field.relationCollection != null) {
      final options = relationOptions[field.name] ?? const [];
      if (field.multiple) {
        final selected = values[field.name] is Set<String>
            ? values[field.name] as Set<String>
            : <String>{};
        return FormField<Set<String>>(
          initialValue: selected,
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'Выберите хотя бы один вариант';
            }
            return serverErrors[field.name];
          },
          builder: (formField) {
            final current = formField.value ?? <String>{};
            return InputDecorator(
              decoration: InputDecoration(
                labelText: field.label,
                border: const OutlineInputBorder(),
                errorText: formField.errorText,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((record) {
                  final id = '${record['id']}';
                  final checked = current.contains(id);
                  return FilterChip(
                    selected: checked,
                    label: Text(
                      entityPrimaryLabel(field.relationCollection!, record),
                    ),
                    onSelected: (selectedNow) {
                      final copy = {...current};
                      if (selectedNow) {
                        copy.add(id);
                      } else {
                        copy.remove(id);
                      }
                      values[field.name] = copy;
                      formField.didChange(copy);
                      setState(() => serverErrors.remove(field.name));
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      }

      return DropdownButtonFormField<String>(
        initialValue: values[field.name] as String?,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map(
              (record) => DropdownMenuItem(
                value: '${record['id']}',
                child: Text(
                  entityPrimaryLabel(field.relationCollection!, record),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        validator: (value) {
          if (field.required && (value == null || value.isEmpty)) {
            return 'Выберите значение';
          }
          return serverErrors[field.name];
        },
        onChanged: (value) {
          setState(() {
            values[field.name] = value;
            serverErrors.remove(field.name);
          });
        },
      );
    }

    final controller = controllers[field.name]!;
    return TextFormField(
      controller: controller,
      minLines: field.type == FieldType.longText ? 3 : 1,
      maxLines: field.type == FieldType.longText ? 5 : 1,
      keyboardType: field.type == FieldType.number
          ? const TextInputType.numberWithOptions(decimal: true)
          : field.type == FieldType.email
              ? TextInputType.emailAddress
              : TextInputType.text,
      decoration: InputDecoration(
        labelText: field.label,
        border: const OutlineInputBorder(),
        helperText: field.type == FieldType.date ? 'Формат: ГГГГ-ММ-ДД' : null,
      ),
      validator: (value) => _validateText(field, value),
      onChanged: (_) {
        if (serverErrors.containsKey(field.name)) {
          setState(() => serverErrors.remove(field.name));
        }
      },
    );
  }

  Map<String, dynamic> _collectData() {
    final data = <String, dynamic>{};
    for (final field in schema.fields) {
      if (controllers.containsKey(field.name)) {
        final text = controllers[field.name]!.text.trim();
        if (field.type == FieldType.number) {
          data[field.name] = text.isEmpty ? null : double.parse(text.replaceAll(',', '.'));
        } else if (field.type == FieldType.date) {
          data[field.name] = text.isEmpty ? '' : '$text 00:00:00.000Z';
        } else {
          data[field.name] = text;
        }
      } else if (field.multiple) {
        final selected = values[field.name] is Set<String>
            ? values[field.name] as Set<String>
            : <String>{};
        data[field.name] = selected.toList();
      } else {
        data[field.name] = values[field.name] ?? '';
      }
    }
    return data;
  }

  Future<void> _save() async {
    setState(() => serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final repository = context.read<EntityRepository>();
    try {
      final data = _collectData();
      final record = widget.editing
          ? await repository.update(schema, widget.id!, data)
          : await repository.create(schema, data);
      if (!mounted) return;
      context.go('/data/${schema.collection}/${record['id']}');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        serverErrors = error.fieldErrors;
        saving = false;
      });
      _formKey.currentState!.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить: $error')),
      );
    }
    if (mounted) setState(() => saving = false);
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Не удалось загрузить форму: $loadError'),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: widget.editing ? 'Редактирование: ${schema.title}' : 'Добавление: ${schema.title}',
            action: OutlinedButton.icon(
              onPressed: () => context.go('/data/${schema.collection}'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('К списку'),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...schema.fields.expand(
                            (field) => [
                              _field(field),
                              const SizedBox(height: 16),
                            ],
                          ),
                          FilledButton.icon(
                            onPressed: saving ? null : _save,
                            icon: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: Text(widget.editing ? 'Сохранить изменения' : 'Создать запись'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
