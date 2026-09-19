import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/entity_schema.dart';
import '../repositories/entity_repository.dart';
import '../widgets/entity_value.dart';
import '../widgets/page_header.dart';

class EntityDetailScreen extends StatefulWidget {
  final String collection;
  final String id;

  const EntityDetailScreen({
    super.key,
    required this.collection,
    required this.id,
  });

  @override
  State<EntityDetailScreen> createState() => _EntityDetailScreenState();
}

class _EntityDetailScreenState extends State<EntityDetailScreen> {
  late EntitySchema schema;
  Map<String, dynamic>? record;
  String? error;
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    schema = schemaByName(widget.collection);
    _load();
  }

  Future<void> _load() async {
    try {
      final loaded = await context.read<EntityRepository>().getOne(schema, widget.id);
      if (mounted) setState(() => record = loaded);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text('Действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<EntityRepository>().delete(schema, widget.id);
      if (mounted) context.go('/data/${schema.collection}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось удалить: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }
    if (record == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: entityPrimaryLabel(schema.collection, record!),
            subtitle: schema.title,
            action: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/data/${schema.collection}'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('К списку'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/data/${schema.collection}/${widget.id}/edit'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Изменить'),
                ),
                IconButton(
                  tooltip: 'Удалить',
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: schema.fields
                          .map(
                            (field) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field.label,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(displayFieldValue(schema, field, record!)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
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
