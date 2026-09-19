import 'package:flutter/material.dart';

import '../core/auth_models.dart';

enum FieldType {
  text,
  longText,
  number,
  email,
  date,
  select,
  relation,
}

class FieldSchema {
  final String name;
  final String label;
  final FieldType type;
  final bool required;
  final bool listColumn;
  final bool searchable;
  final bool filterable;
  final bool sortable;
  final int? minLength;
  final int? maxLength;
  final double? min;
  final double? max;
  final Map<String, String> options;
  final String? relationCollection;
  final bool multiple;

  const FieldSchema({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.listColumn = false,
    this.searchable = false,
    this.filterable = false,
    this.sortable = false,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.options = const {},
    this.relationCollection,
    this.multiple = false,
  });
}

class EntitySchema {
  final String collection;
  final String title;
  final String singular;
  final String primaryField;
  final IconData icon;
  final UserRole ownerRole;
  final List<FieldSchema> fields;
  final String defaultSort;

  const EntitySchema({
    required this.collection,
    required this.title,
    required this.singular,
    required this.primaryField,
    required this.icon,
    required this.ownerRole,
    required this.fields,
    this.defaultSort = 'id',
  });

  List<FieldSchema> get searchFields =>
      fields.where((field) => field.searchable).toList();

  List<FieldSchema> get filterFields =>
      fields.where((field) => field.filterable).toList();

  List<FieldSchema> get sortFields =>
      fields.where((field) => field.sortable).toList();

  List<FieldSchema> get listFields =>
      fields.where((field) => field.listColumn).toList();

  List<FieldSchema> get relationFields =>
      fields.where((field) => field.type == FieldType.relation).toList();
}

const entitySchemas = <String, EntitySchema>{
  'clients': EntitySchema(
    collection: 'clients',
    title: 'Заказчики',
    singular: 'заказчика',
    primaryField: 'name',
    icon: Icons.business_center_outlined,
    ownerRole: UserRole.manager,
    fields: [
      FieldSchema(
        name: 'name',
        label: 'Наименование',
        type: FieldType.text,
        required: true,
        minLength: 2,
        maxLength: 100,
        listColumn: true,
        searchable: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'inn',
        label: 'ИНН',
        type: FieldType.text,
        required: true,
        minLength: 10,
        maxLength: 12,
        listColumn: true,
        searchable: true,
      ),
      FieldSchema(
        name: 'email',
        label: 'E-mail',
        type: FieldType.email,
        required: true,
        maxLength: 120,
        listColumn: true,
        searchable: true,
      ),
      FieldSchema(
        name: 'phone',
        label: 'Телефон',
        type: FieldType.text,
        maxLength: 30,
      ),
      FieldSchema(
        name: 'country',
        label: 'Страна',
        type: FieldType.select,
        required: true,
        filterable: true,
        listColumn: true,
        options: {
          'Россия': 'Россия',
          'Беларусь': 'Беларусь',
          'Казахстан': 'Казахстан',
        },
      ),
    ],
  ),
  'engineers': EntitySchema(
    collection: 'engineers',
    title: 'Инженеры',
    singular: 'инженера',
    primaryField: 'fullName',
    icon: Icons.engineering_outlined,
    ownerRole: UserRole.manager,
    fields: [
      FieldSchema(
        name: 'fullName',
        label: 'ФИО',
        type: FieldType.text,
        required: true,
        minLength: 3,
        maxLength: 120,
        listColumn: true,
        searchable: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'specialization',
        label: 'Специализация',
        type: FieldType.select,
        required: true,
        filterable: true,
        listColumn: true,
        options: {
          'Конструкции': 'Конструкции',
          'Фасады': 'Фасады',
          'Динамика': 'Динамика',
        },
      ),
      FieldSchema(
        name: 'experience',
        label: 'Стаж, лет',
        type: FieldType.number,
        required: true,
        min: 0,
        max: 50,
        listColumn: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'email',
        label: 'E-mail',
        type: FieldType.email,
        required: true,
        maxLength: 120,
        listColumn: true,
        searchable: true,
      ),
    ],
  ),
  'projects': EntitySchema(
    collection: 'projects',
    title: 'Проекты',
    singular: 'проект',
    primaryField: 'name',
    icon: Icons.folder_copy_outlined,
    ownerRole: UserRole.manager,
    defaultSort: '-deadline',
    fields: [
      FieldSchema(
        name: 'name',
        label: 'Название',
        type: FieldType.text,
        required: true,
        minLength: 3,
        maxLength: 120,
        listColumn: true,
        searchable: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'code',
        label: 'Шифр проекта',
        type: FieldType.text,
        required: true,
        minLength: 2,
        maxLength: 30,
        listColumn: true,
        searchable: true,
      ),
      FieldSchema(
        name: 'client',
        label: 'Заказчик',
        type: FieldType.relation,
        relationCollection: 'clients',
        required: true,
        filterable: true,
        listColumn: true,
      ),
      FieldSchema(
        name: 'leadEngineer',
        label: 'Главный инженер',
        type: FieldType.relation,
        relationCollection: 'engineers',
        required: true,
        filterable: true,
        listColumn: true,
      ),
      FieldSchema(
        name: 'status',
        label: 'Статус',
        type: FieldType.select,
        required: true,
        filterable: true,
        listColumn: true,
        sortable: true,
        options: {
          'Новый': 'Новый',
          'В работе': 'В работе',
          'На проверке': 'На проверке',
          'Завершён': 'Завершён',
        },
      ),
      FieldSchema(
        name: 'deadline',
        label: 'Срок',
        type: FieldType.date,
        required: true,
        listColumn: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'description',
        label: 'Описание',
        type: FieldType.longText,
        maxLength: 500,
      ),
    ],
  ),
  'materials': EntitySchema(
    collection: 'materials',
    title: 'Материалы',
    singular: 'материал',
    primaryField: 'name',
    icon: Icons.view_in_ar_outlined,
    ownerRole: UserRole.engineer,
    fields: [
      FieldSchema(
        name: 'name',
        label: 'Название',
        type: FieldType.text,
        required: true,
        maxLength: 80,
        listColumn: true,
        searchable: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'grade',
        label: 'Марка',
        type: FieldType.text,
        required: true,
        maxLength: 50,
        listColumn: true,
        searchable: true,
      ),
      FieldSchema(
        name: 'elasticModulus',
        label: 'Модуль E, МПа',
        type: FieldType.number,
        required: true,
        min: 1000,
        max: 500000,
        listColumn: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'yieldStrength',
        label: 'Предел текучести, МПа',
        type: FieldType.number,
        required: true,
        min: 10,
        max: 5000,
        listColumn: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'density',
        label: 'Плотность, кг/м³',
        type: FieldType.number,
        required: true,
        min: 100,
        max: 30000,
      ),
    ],
  ),
  'sections': EntitySchema(
    collection: 'sections',
    title: 'Сечения',
    singular: 'сечение',
    primaryField: 'name',
    icon: Icons.crop_square_outlined,
    ownerRole: UserRole.engineer,
    fields: [
      FieldSchema(
        name: 'name',
        label: 'Обозначение',
        type: FieldType.text,
        required: true,
        maxLength: 80,
        listColumn: true,
        searchable: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'type',
        label: 'Тип сечения',
        type: FieldType.select,
        required: true,
        filterable: true,
        listColumn: true,
        options: {
          'Труба': 'Труба',
          'Уголок': 'Уголок',
          'Двутавр': 'Двутавр',
          'Полоса': 'Полоса',
        },
      ),
      FieldSchema(
        name: 'material',
        label: 'Материал',
        type: FieldType.relation,
        relationCollection: 'materials',
        required: true,
        filterable: true,
        listColumn: true,
      ),
      FieldSchema(
        name: 'area',
        label: 'Площадь, мм²',
        type: FieldType.number,
        required: true,
        min: 1,
        max: 1000000,
        listColumn: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'inertia',
        label: 'Момент инерции, мм⁴',
        type: FieldType.number,
        required: true,
        min: 1,
        max: 1000000000000,
        listColumn: true,
        sortable: true,
      ),
    ],
  ),
  'load_cases': EntitySchema(
    collection: 'load_cases',
    title: 'Нагрузки',
    singular: 'нагрузку',
    primaryField: 'name',
    icon: Icons.south_east_outlined,
    ownerRole: UserRole.engineer,
    fields: [
      FieldSchema(
        name: 'name',
        label: 'Название',
        type: FieldType.text,
        required: true,
        maxLength: 100,
        listColumn: true,
        searchable: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'kind',
        label: 'Тип нагрузки',
        type: FieldType.select,
        required: true,
        filterable: true,
        listColumn: true,
        options: {
          'Ветер': 'Ветер',
          'Снег': 'Снег',
          'Собственный вес': 'Собственный вес',
          'Барьерная': 'Барьерная',
        },
      ),
      FieldSchema(
        name: 'value',
        label: 'Значение',
        type: FieldType.number,
        required: true,
        min: 0,
        max: 1000000,
        listColumn: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'unit',
        label: 'Единица',
        type: FieldType.select,
        required: true,
        listColumn: true,
        options: {
          'кПа': 'кПа',
          'кН/м': 'кН/м',
          'кН': 'кН',
        },
      ),
      FieldSchema(
        name: 'description',
        label: 'Описание',
        type: FieldType.longText,
        maxLength: 300,
      ),
    ],
  ),
  'calculations': EntitySchema(
    collection: 'calculations',
    title: 'Расчёты',
    singular: 'расчёт',
    primaryField: 'title',
    icon: Icons.calculate_outlined,
    ownerRole: UserRole.engineer,
    defaultSort: 'title',
    fields: [
      FieldSchema(
        name: 'title',
        label: 'Название расчёта',
        type: FieldType.text,
        required: true,
        minLength: 3,
        maxLength: 120,
        listColumn: true,
        searchable: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'project',
        label: 'Проект',
        type: FieldType.relation,
        relationCollection: 'projects',
        required: true,
        filterable: true,
        listColumn: true,
      ),
      FieldSchema(
        name: 'engineer',
        label: 'Инженер',
        type: FieldType.relation,
        relationCollection: 'engineers',
        required: true,
        filterable: true,
        listColumn: true,
      ),
      FieldSchema(
        name: 'section',
        label: 'Сечение',
        type: FieldType.relation,
        relationCollection: 'sections',
        required: true,
        listColumn: true,
      ),
      FieldSchema(
        name: 'loadCases',
        label: 'Нагрузки',
        type: FieldType.relation,
        relationCollection: 'load_cases',
        required: true,
        multiple: true,
      ),
      FieldSchema(
        name: 'calcType',
        label: 'Тип расчёта',
        type: FieldType.select,
        required: true,
        filterable: true,
        listColumn: true,
        options: {
          'Прочность': 'Прочность',
          'Прогиб': 'Прогиб',
          'Устойчивость': 'Устойчивость',
        },
      ),
      FieldSchema(
        name: 'status',
        label: 'Статус',
        type: FieldType.select,
        required: true,
        filterable: true,
        listColumn: true,
        sortable: true,
        options: {
          'Черновик': 'Черновик',
          'Рассчитан': 'Рассчитан',
          'На проверке': 'На проверке',
        },
      ),
      FieldSchema(
        name: 'utilization',
        label: 'Коэффициент использования',
        type: FieldType.number,
        required: true,
        min: 0,
        max: 10,
        listColumn: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'result',
        label: 'Результат',
        type: FieldType.longText,
        required: true,
        maxLength: 500,
      ),
    ],
  ),
  'reviews': EntitySchema(
    collection: 'reviews',
    title: 'Проверки',
    singular: 'проверку',
    primaryField: 'reviewer',
    icon: Icons.fact_check_outlined,
    ownerRole: UserRole.reviewer,
    defaultSort: '-checkedAt',
    fields: [
      FieldSchema(
        name: 'calculation',
        label: 'Расчёт',
        type: FieldType.relation,
        relationCollection: 'calculations',
        required: true,
        filterable: true,
        listColumn: true,
      ),
      FieldSchema(
        name: 'reviewer',
        label: 'Проверяющий',
        type: FieldType.text,
        required: true,
        minLength: 3,
        maxLength: 120,
        listColumn: true,
        searchable: true,
        sortable: true,
      ),
      FieldSchema(
        name: 'decision',
        label: 'Решение',
        type: FieldType.select,
        required: true,
        filterable: true,
        listColumn: true,
        options: {
          'Согласовано': 'Согласовано',
          'На доработку': 'На доработку',
          'Отклонено': 'Отклонено',
        },
      ),
      FieldSchema(
        name: 'comment',
        label: 'Комментарий',
        type: FieldType.longText,
        required: true,
        maxLength: 500,
      ),
      FieldSchema(
        name: 'checkedAt',
        label: 'Дата проверки',
        type: FieldType.date,
        required: true,
        listColumn: true,
        sortable: true,
      ),
    ],
  ),
};

EntitySchema schemaByName(String collection) {
  final schema = entitySchemas[collection];
  if (schema == null) {
    throw StateError('Неизвестная сущность: $collection');
  }
  return schema;
}
