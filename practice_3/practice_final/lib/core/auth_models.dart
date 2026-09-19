import 'package:flutter/foundation.dart';

enum UserRole {
  engineer,
  reviewer,
  manager;

  String get title {
    switch (this) {
      case UserRole.engineer:
        return 'Инженер';
      case UserRole.reviewer:
        return 'Проверяющий';
      case UserRole.manager:
        return 'Руководитель';
    }
  }

  static UserRole? fromValue(String? value) {
    for (final role in UserRole.values) {
      if (role.name == value) {
        return role;
      }
    }
    return null;
  }
}

@immutable
class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: '${json['id'] ?? ''}',
      email: '${json['email'] ?? ''}',
      name: '${json['name'] ?? ''}',
      role: UserRole.fromValue('${json['role'] ?? ''}') ?? UserRole.engineer,
    );
  }
}
