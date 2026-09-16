class Loan {
  final int id;

  final int? readerId;
  final String readerName;

  final int? bookId;
  final String bookTitle;

  final DateTime issuedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;

  final String status;
  final DateTime? deletedAt;

  const Loan({
    required this.id,
    required this.readerId,
    required this.readerName,
    required this.bookId,
    required this.bookTitle,
    required this.issuedAt,
    required this.dueAt,
    required this.returnedAt,
    required this.status,
    required this.deletedAt,
  });

  factory Loan.fromJson(
    Map<String, dynamic> json,
  ) {
    final reader =
        json['reader'];

    final book =
        json['book'];

    return Loan(
      id: _toInt(
        json['id'],
      ),

      readerId:
          reader is Map<String, dynamic>
              ? _toNullableInt(
                  reader['id'],
                )
              : null,

      readerName:
          reader is Map<String, dynamic>
              ? reader['fullName']
                      ?.toString() ??
                  'Неизвестный читатель'
              : 'Неизвестный читатель',

      bookId:
          book is Map<String, dynamic>
              ? _toNullableInt(
                  book['id'],
                )
              : null,

      bookTitle:
          book is Map<String, dynamic>
              ? book['title']
                      ?.toString() ??
                  'Неизвестная книга'
              : 'Неизвестная книга',

      issuedAt:
          _toDateTime(
        json['issuedAt'],
      ),

      dueAt:
          _toDateTime(
        json['dueAt'],
      ),

      returnedAt:
          _toNullableDateTime(
        json['returnedAt'],
      ),

      status:
          json['status']
                  ?.toString() ??
              'active',

      deletedAt:
          _toNullableDateTime(
        json['deletedAt'],
      ),
    );
  }

  bool get isActive =>
      status == 'active';

  bool get isOverdue =>
      status == 'overdue';

  bool get isReturned =>
      status == 'returned';

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.parse(
      value.toString(),
    );
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

  static DateTime _toDateTime(
    dynamic value,
  ) {
    return DateTime.parse(
      value.toString(),
    );
  }

  static DateTime? _toNullableDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      text,
    );
  }
}