class Author {
  final int id;
  final String fullName;
  final int? birthYear;
  final String country;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.fullName,
    this.birthYear,
    required this.country,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Author copyWith({
    String? fullName,
    Object? birthYear = _unset,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      fullName: fullName ?? this.fullName,
      birthYear: birthYear == _unset
          ? this.birthYear
          : birthYear as int?,
      country: country ?? this.country,
      deletedAt: clearDeletedAt
          ? null
          : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'birthYear': birthYear,
      'country': country,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Author.fromJson(
    Map<String, dynamic> json,
  ) {
    return Author(
      id: _toInt(json['id']),
      fullName:
          json['fullName']?.toString() ?? '',
      birthYear: _toNullableInt(
        json['birthYear'],
      ),
      country:
          json['country']?.toString() ?? '',
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