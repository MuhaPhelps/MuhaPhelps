import '../models/entity_schema.dart';
import '../models/page_result.dart';

abstract class EntityRepository {
  Future<PageResult<Map<String, dynamic>>> list(
    EntitySchema schema, {
    required int page,
    required int perPage,
    required String search,
    required Map<String, String> filters,
    required String sort,
  });

  Future<Map<String, dynamic>> getOne(EntitySchema schema, String id);

  Future<List<Map<String, dynamic>>> getOptions(String collection);

  Future<Map<String, dynamic>> create(
    EntitySchema schema,
    Map<String, dynamic> data,
  );

  Future<Map<String, dynamic>> update(
    EntitySchema schema,
    String id,
    Map<String, dynamic> data,
  );

  Future<void> delete(EntitySchema schema, String id);
}
