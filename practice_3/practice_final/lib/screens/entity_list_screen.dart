import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/entity_schema.dart';
import '../repositories/entity_repository.dart';
import '../state/entity_list_controller.dart';
import '../widgets/entity_value.dart';
import '../widgets/page_header.dart';

class EntityListScreen extends StatefulWidget {
  final String collection;
  final Uri uri;

  const EntityListScreen({
    super.key,
    required this.collection,
    required this.uri,
  });

  @override
  State<EntityListScreen> createState() => _EntityListScreenState();
}

class _EntityListScreenState extends State<EntityListScreen> {
  late EntitySchema schema;
  late EntityListController controller;
  final searchController = TextEditingController();
  final Map<String, String?> filterValues = {};
  final Map<String, List<Map<String, dynamic>>> relationOptions = {};
  String sortValue = '';
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    schema = schemaByName(widget.collection);
    controller = EntityListController(
      repository: context.read<EntityRepository>(),
      schema: schema,
    );
    _syncFromUri(widget.uri);
    controller.load(widget.uri);
    _loadRelationOptions();
  }

  @override
  void didUpdateWidget(covariant EntityListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri.toString() != widget.uri.toString()) {
      _syncFromUri(widget.uri);
      controller.load(widget.uri);
    }
  }

  void _syncFromUri(Uri uri) {
    searchController.text = uri.queryParameters['search'] ?? '';
    sortValue = uri.queryParameters['sort'] ?? schema.defaultSort;
    for (final field in schema.filterFields) {
      filterValues[field.name] = uri.queryParameters[field.name];
    }
  }

  Future<void> _loadRelationOptions() async {
    final repository = context.read<EntityRepository>();
    for (final field in schema.filterFields) {
      if (field.type == FieldType.relation && field.relationCollection != null) {
        try {
          relationOptions[field.name] =
              await repository.getOptions(field.relationCollection!);
        } catch (_) {
          relationOptions[field.name] = const [];
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _applyFilters() {
    final params = <String, String>{};
    final search = searchController.text.trim();
    if (search.isNotEmpty) params['search'] = search;
    for (final field in schema.filterFields) {
      final value = filterValues[field.name];
      if (value != null && value.isNotEmpty) params[field.name] = value;
    }
    if (sortValue.isNotEmpty) params['sort'] = sortValue;
    params['page'] = '1';
    context.go(Uri(path: '/data/${schema.collection}', queryParameters: params).toString());
  }

  void _goToPage(int page) {
    final params = Map<String, String>.from(widget.uri.queryParameters);
    params['page'] = '$page';
    context.go(Uri(path: '/data/${schema.collection}', queryParameters: params).toString());
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text(
          'Запись «${entityPrimaryLabel(schema.collection, record)}» будет удалена.',
        ),
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
      await context.read<EntityRepository>().delete(schema, '${record['id']}');
      await controller.load(widget.uri);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось удалить: $error')),
      );
    }
  }

  Widget _filterWidget(FieldSchema field) {
    if (field.type == FieldType.select) {
      return SizedBox(
        width: 210,
        child: DropdownButtonFormField<String>(
          key: ValueKey('${field.name}:${filterValues[field.name] ?? ''}'),
          initialValue: filterValues[field.name],
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('Все')),
            ...field.options.entries.map(
              (entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (value) => filterValues[field.name] = value,
        ),
      );
    }

    if (field.type == FieldType.relation && field.relationCollection != null) {
      final options = relationOptions[field.name] ?? const [];
      final current = filterValues[field.name];
      final hasCurrent = current == null ||
          current.isEmpty ||
          options.any((record) => '${record['id']}' == current);
      return SizedBox(
        width: 230,
        child: DropdownButtonFormField<String>(
          key: ValueKey('${field.name}:${current ?? ''}'),
          initialValue: current,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('Все')),
            if (!hasCurrent)
              DropdownMenuItem(value: current, child: const Text('Выбранная запись')),
            ...options.map(
              (record) => DropdownMenuItem(
                value: '${record['id']}',
                child: Text(
                  entityPrimaryLabel(field.relationCollection!, record),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (value) => filterValues[field.name] = value,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  List<DropdownMenuItem<String>> _sortItems() {
    final items = <DropdownMenuItem<String>>[];
    for (final field in schema.sortFields) {
      items.add(
        DropdownMenuItem(
          value: field.name,
          child: Text('${field.label} ↑'),
        ),
      );
      items.add(
        DropdownMenuItem(
          value: '-${field.name}',
          child: Text('${field.label} ↓'),
        ),
      );
    }
    if (items.every((item) => item.value != schema.defaultSort)) {
      items.add(
        DropdownMenuItem(
          value: schema.defaultSort,
          child: const Text('По умолчанию'),
        ),
      );
    }
    return items;
  }

  @override
  void dispose() {
    controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: schema.title,
              subtitle: 'Поиск, фильтры, сортировка и пагинация выполняются на сервере.',
              action: FilledButton.icon(
                onPressed: () => context.go('/data/${schema.collection}/new'),
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Поиск',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _applyFilters(),
                    ),
                  ),
                  ...schema.filterFields.take(3).map(_filterWidget),
                  if (schema.sortFields.isNotEmpty)
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('sort:$sortValue'),
                        initialValue: sortValue,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Сортировка',
                          border: OutlineInputBorder(),
                        ),
                        items: _sortItems(),
                        onChanged: (value) => sortValue = value ?? schema.defaultSort,
                      ),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Применить'),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/data/${schema.collection}'),
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Сбросить'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    switch (controller.status) {
      case ListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ListStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 56),
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage ?? 'Ошибка загрузки',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => controller.load(widget.uri),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        );
      case ListStatus.empty:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('По заданным условиям записей не найдено.'),
          ),
        );
      case ListStatus.data:
        return _buildData();
    }
  }

  Widget _buildData() {
    final result = controller.result!;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: constraints.maxWidth < 800
                  ? ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: result.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _recordCard(result.items[index]),
                    )
                  : _recordTable(result.items),
            ),
            _pagination(result.page, result.totalPages, result.totalItems),
          ],
        );
      },
    );
  }

  Widget _recordCard(Map<String, dynamic> record) {
    return Card(
      child: ListTile(
        title: Text(
          entityPrimaryLabel(schema.collection, record),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: schema.listFields
                .where((field) => field.name != schema.primaryField)
                .take(3)
                .map(
                  (field) => Text(
                    '${field.label}: ${displayFieldValue(schema, field, record)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
                .toList(),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              context.go('/data/${schema.collection}/${record['id']}');
            } else if (value == 'edit') {
              context.go('/data/${schema.collection}/${record['id']}/edit');
            } else if (value == 'delete') {
              _deleteRecord(record);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'view', child: Text('Открыть')),
            PopupMenuItem(value: 'edit', child: Text('Изменить')),
            PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
        ),
      ),
    );
  }

  Widget _recordTable(List<Map<String, dynamic>> items) {
    final fields = schema.listFields.take(5).toList();
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: [
              ...fields.map((field) => DataColumn(label: Text(field.label))),
              const DataColumn(label: Text('Действия')),
            ],
            rows: items
                .map(
                  (record) => DataRow(
                    cells: [
                      ...fields.map(
                        (field) => DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Text(
                              displayFieldValue(schema, field, record),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Открыть',
                              onPressed: () => context.go(
                                '/data/${schema.collection}/${record['id']}',
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            IconButton(
                              tooltip: 'Изменить',
                              onPressed: () => context.go(
                                '/data/${schema.collection}/${record['id']}/edit',
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Удалить',
                              onPressed: () => _deleteRecord(record),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _pagination(int page, int totalPages, int totalItems) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          IconButton(
            tooltip: 'Предыдущая страница',
            onPressed: page > 1 ? () => _goToPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Страница $page из ${totalPages == 0 ? 1 : totalPages} · всего $totalItems'),
          IconButton(
            tooltip: 'Следующая страница',
            onPressed: page < totalPages ? () => _goToPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
