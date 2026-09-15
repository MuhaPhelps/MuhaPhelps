import 'library_card.dart';

class Reader {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LibraryCard card;
  final DateTime? deletedAt;

  const Reader({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Reader copyWith({
    String? fullName,
    String? email,
    String? phone,
    LibraryCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Reader(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: card ?? this.card,
      deletedAt: clearDeletedAt
          ? null
          : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'card': card.toJson(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Reader.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawCard = json['card'];

    return Reader(
      id: _toInt(json['id']),
      fullName:
          json['fullName']?.toString() ?? '',
      email:
          json['email']?.toString() ?? '',
      phone:
          json['phone']?.toString() ?? '',
      card: rawCard is Map
          ? LibraryCard.fromJson(
              Map<String, dynamic>.from(
                rawCard,
              ),
            )
          : const LibraryCard.empty(),
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