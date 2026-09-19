import '../core/api_client.dart';
import '../models/entity_schema.dart';
import '../models/page_result.dart';
import 'entity_repository.dart';

class PocketBaseRepository implements EntityRepository {
  final ApiClient api;

  PocketBaseRepository(this.api);

  String _escape(String value) => value.replaceAll('"', '\\"');

  String _expand(EntitySchema schema) {
    return schema.relationFields.map((field) => field.name).join(',');
  }

  @override
  Future<PageResult<Map<String, dynamic>>> list(
    EntitySchema schema, {
    required int page,
    required int perPage,
    required String search,
    required Map<String, String> filters,
    required String sort,
  }) async {
    final clauses = <String>[];

    if (search.trim().isNotEmpty && schema.searchFields.isNotEmpty) {
      final escaped = _escape(search.trim());
      final searchClause = schema.searchFields
          .map((field) => '${field.name}~"$escaped"')
          .join(' || ');
      clauses.add('($searchClause)');
    }

    for (final field in schema.filterFields) {
      final value = filters[field.name];
      if (value == null || value.isEmpty) {
        continue;
      }
      clauses.add('${field.name}="${_escape(value)}"');
    }

    final query = <String, dynamic>{
      'page': page,
      'perPage': perPage,
      'sort': sort.isEmpty ? schema.defaultSort : sort,
    };

    final expand = _expand(schema);
    if (expand.isNotEmpty) {
      query['expand'] = expand;
    }
    if (clauses.isNotEmpty) {
      query['filter'] = clauses.join(' && ');
    }

    final data = await api.get(
      '/api/collections/${schema.collection}/records',
      queryParameters: query,
    );

    final rawItems = data['items'] as List? ?? const [];
    return PageResult(
      page: data['page'] as int? ?? page,
      perPage: data['perPage'] as int? ?? perPage,
      totalPages: data['totalPages'] as int? ?? 0,
      totalItems: data['totalItems'] as int? ?? 0,
      items: rawItems
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }

  @override
  Future<Map<String, dynamic>> getOne(
    EntitySchema schema,
    String id,
  ) async {
    final expand = _expand(schema);
    return api.get(
      '/api/collections/${schema.collection}/records/$id',
      queryParameters: expand.isEmpty ? null : {'expand': expand},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getOptions(String collection) async {
    final schema = schemaByName(collection);
    final data = await api.get(
      '/api/collections/$collection/records',
      queryParameters: {
        'page': 1,
        'perPage': 200,
        'sort': schema.primaryField,
      },
    );
    final items = data['items'] as List? ?? const [];
    return items
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> create(
    EntitySchema schema,
    Map<String, dynamic> data,
  ) {
    return api.post(
      '/api/collections/${schema.collection}/records',
      data: data,
    );
  }

  @override
  Future<Map<String, dynamic>> update(
    EntitySchema schema,
    String id,
    Map<String, dynamic> data,
  ) {
    return api.patch(
      '/api/collections/${schema.collection}/records/$id',
      data: data,
    );
  }

  @override
  Future<void> delete(EntitySchema schema, String id) {
    return api.delete('/api/collections/${schema.collection}/records/$id');
  }
}
