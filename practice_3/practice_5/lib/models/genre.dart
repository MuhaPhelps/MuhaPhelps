class Genre {
  final int id;
  final String name;
  final String description;
  final DateTime? deletedAt;

  const Genre({
    required this.id,
    required this.name,
    required this.description,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Genre copyWith({
    String? name,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Genre(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      deletedAt: clearDeletedAt
          ? null
          : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Genre.fromJson(
    Map<String, dynamic> json,
  ) {
    return Genre(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      description:
          json['description']?.toString() ?? '',
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
}