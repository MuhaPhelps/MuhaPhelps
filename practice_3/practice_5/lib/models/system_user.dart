class SystemUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final int? readerId;

  const SystemUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    required this.readerId,
  });

  factory SystemUser.fromJson(
    Map<String, dynamic> json,
  ) {
    return SystemUser(
      id: _toInt(
        json['id'],
      ),
      username:
          json['username']
                  ?.toString() ??
              '',
      fullName:
          json['fullName']
                  ?.toString() ??
              '',
      email:
          json['email']
                  ?.toString() ??
              '',
      role:
          json['role']
                  ?.toString() ??
              '',
      readerId:
          _toNullableInt(
        json['readerId'],
      ),
    );
  }

  String get roleTitle {
    switch (role) {
      case 'admin':
        return 'Администратор';

      case 'librarian':
        return 'Библиотекарь';

      case 'reader':
        return 'Читатель';

      default:
        return role;
    }
  }

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
}