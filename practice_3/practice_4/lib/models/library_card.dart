class LibraryCard {
  final int id;
  final String number;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  const LibraryCard({
    required this.id,
    required this.number,
    this.issuedAt,
    this.expiresAt,
  });

  const LibraryCard.empty()
      : id = 0,
        number = '',
        issuedAt = null,
        expiresAt = null;

  LibraryCard copyWith({
    int? id,
    String? number,
    Object? issuedAt = _unset,
    Object? expiresAt = _unset,
  }) {
    return LibraryCard(
      id: id ?? this.id,
      number: number ?? this.number,
      issuedAt: issuedAt == _unset
          ? this.issuedAt
          : issuedAt as DateTime?,
      expiresAt: expiresAt == _unset
          ? this.expiresAt
          : expiresAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'issuedAt': issuedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory LibraryCard.fromJson(
    Map<String, dynamic> json,
  ) {
    return LibraryCard(
      id: _toInt(json['id']),
      number: json['number']?.toString() ?? '',
      issuedAt: _toDateTime(
        json['issuedAt'],
      ),
      expiresAt: _toDateTime(
        json['expiresAt'],
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

  static const _unset = Object();
}