class Publisher {
  final int id;
  final String name;
  final String city;
  final int? foundedYear;
  final DateTime? deletedAt;

  const Publisher({
    required this.id,
    required this.name,
    required this.city,
    this.foundedYear,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Publisher copyWith({
    String? name,
    String? city,
    Object? foundedYear = _unset,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Publisher(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      foundedYear: foundedYear == _unset
          ? this.foundedYear
          : foundedYear as int?,
      deletedAt: clearDeletedAt
          ? null
          : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'foundedYear': foundedYear,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Publisher.fromJson(
    Map<String, dynamic> json,
  ) {
    return Publisher(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      foundedYear: _toNullableInt(
        json['foundedYear'],
      ),
      deletedAt: _toDateTime(
        json['deletedAt'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static int? _toNullableInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static const _unset = Object();
}