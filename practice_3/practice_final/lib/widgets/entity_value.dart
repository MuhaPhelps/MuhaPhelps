import '../models/entity_schema.dart';

String entityPrimaryLabel(String collection, Map<String, dynamic> record) {
  final schema = schemaByName(collection);
  final value = record[schema.primaryField];
  return value == null || '$value'.isEmpty ? record['id']?.toString() ?? '—' : '$value';
}

String displayFieldValue(
  EntitySchema schema,
  FieldSchema field,
  Map<String, dynamic> record,
) {
  final value = record[field.name];

  if (field.type == FieldType.relation && field.relationCollection != null) {
    final expand = record['expand'];
    if (expand is Map) {
      final expandedValue = expand[field.name];
      if (expandedValue is Map) {
        return entityPrimaryLabel(
          field.relationCollection!,
          Map<String, dynamic>.from(expandedValue),
        );
      }
      if (expandedValue is List) {
        final labels = expandedValue
            .whereType<Map>()
            .map(
              (item) => entityPrimaryLabel(
                field.relationCollection!,
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
        return labels.isEmpty ? '—' : labels.join(', ');
      }
    }
    if (value is List) {
      return value.isEmpty ? '—' : '${value.length} шт.';
    }
    return value == null || '$value'.isEmpty ? '—' : '$value';
  }

  if (field.type == FieldType.date) {
    final text = value?.toString() ?? '';
    if (text.length >= 10) return text.substring(0, 10);
  }

  if (field.type == FieldType.number && value is num) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  final text = value?.toString() ?? '';
  return text.isEmpty ? '—' : text;
}
