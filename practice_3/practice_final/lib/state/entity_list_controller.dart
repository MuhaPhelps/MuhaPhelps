import 'package:flutter/foundation.dart';

import '../models/entity_schema.dart';
import '../models/page_result.dart';
import '../repositories/entity_repository.dart';

enum ListStatus { loading, data, empty, error }

class EntityListController extends ChangeNotifier {
  final EntityRepository repository;
  final EntitySchema schema;

  ListStatus status = ListStatus.loading;
  PageResult<Map<String, dynamic>>? result;
  String? errorMessage;

  EntityListController({required this.repository, required this.schema});

  Future<void> load(Uri uri) async {
    status = ListStatus.loading;
    errorMessage = null;
    notifyListeners();

    final page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
    final search = uri.queryParameters['search'] ?? '';
    final sort = uri.queryParameters['sort'] ?? schema.defaultSort;
    final filters = <String, String>{};
    for (final field in schema.filterFields) {
      final value = uri.queryParameters[field.name];
      if (value != null && value.isNotEmpty) {
        filters[field.name] = value;
      }
    }

    try {
      result = await repository.list(
        schema,
        page: page,
        perPage: 8,
        search: search,
        filters: filters,
        sort: sort,
      );
      status = result!.items.isEmpty ? ListStatus.empty : ListStatus.data;
    } catch (error) {
      errorMessage = '$error';
      status = ListStatus.error;
    }
    notifyListeners();
  }
}
