import 'package:dio/dio.dart';

import '../core/api_exception.dart';
import '../core/auth_models.dart';
import '../core/config.dart';

class AuthResult {
  final String token;
  final AppUser user;

  const AuthResult({required this.token, required this.user});
}

class AuthRepository {
  late final Dio _dio;

  AuthRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/collections/users/auth-with-password',
        data: {'identity': email.trim(), 'password': password},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      return AuthResult(
        token: '${data['token'] ?? ''}',
        user: AppUser.fromJson(
          Map<String, dynamic>.from(data['record'] as Map),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/api/collections/users/records',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'passwordConfirm': password,
          'role': 'engineer',
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuthResult> refresh(String token) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/collections/users/auth-refresh',
        options: Options(headers: {'Authorization': token}),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      return AuthResult(
        token: '${data['token'] ?? ''}',
        user: AppUser.fromJson(
          Map<String, dynamic>.from(data['record'] as Map),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
