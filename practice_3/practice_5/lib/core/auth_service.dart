import 'package:dio/dio.dart';

import 'api_exceptions.dart';
import 'auth_session.dart';

class AuthService {
  final Dio _dio;
  final AuthSession _session;

  AuthService(
    this._dio,
    this._session,
  );

  Future<AppUser> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) {
    return guard(() async {
      final response =
          await _dio.post(
        '/auth/register',
        data: {
          'username':
              username.trim(),
          'password':
              password,
          'fullName':
              fullName.trim(),
          'email':
              email.trim(),
        },
      );

      final data =
          response.data;

      if (data is! Map) {
        throw const ServerException(
          'Сервер вернул некорректный ответ регистрации.',
        );
      }

      return AppUser.fromJson(
        Map<String, dynamic>.from(
          data,
        ),
      );
    });
  }

  Future<AppUser> login(
    String username,
    String password,
  ) {
    return guard(() async {
      final response =
          await _dio.post(
        '/auth/login',
        data: {
          'username':
              username.trim(),
          'password':
              password,
        },
      );

      final data =
          response.data;

      if (data is! Map) {
        throw const ServerException(
          'Сервер вернул некорректный ответ входа.',
        );
      }

      final accessToken =
          data['accessToken']
              ?.toString();

      final refreshToken =
          data['refreshToken']
              ?.toString();

      final expiresIn =
          int.tryParse(
        data['expiresIn']
                ?.toString() ??
            '',
      );

      final userData =
          data['user'];

      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty ||
          expiresIn == null ||
          userData is! Map) {
        throw const ServerException(
          'Ответ сервера не содержит данные сессии.',
        );
      }

      final user =
          AppUser.fromJson(
        Map<String, dynamic>.from(
          userData,
        ),
      );

      _session.updateTokens(
        accessToken:
            accessToken,
        refreshToken:
            refreshToken,
        expiresIn:
            expiresIn,
      );

      _session.setUser(
        user,
      );

      await _session
          .persistTokens();

      return user;
    });
  }

  Future<AppUser> me() {
    return guard(() async {
      final response =
          await _dio.get(
        '/auth/me',
      );

      final data =
          response.data;

      if (data is! Map) {
        throw const ServerException(
          'Сервер вернул некорректные данные пользователя.',
        );
      }

      final dynamic rawUser =
          data['user'] is Map
              ? data['user']
              : data;

      if (rawUser is! Map) {
        throw const ServerException(
          'Сервер не вернул пользователя.',
        );
      }

      final user =
          AppUser.fromJson(
        Map<String, dynamic>.from(
          rawUser,
        ),
      );

      _session.setUser(
        user,
      );

      return user;
    });
  }

  Future<void> refresh() {
    return guard(() async {
      final refreshToken =
          _session.refreshToken;

      if (refreshToken == null ||
          refreshToken.isEmpty) {
        throw const UnauthorizedException(
          'Токен обновления отсутствует.',
        );
      }

      final response =
          await _dio.post(
        '/auth/refresh',
        data: {
          'refreshToken':
              refreshToken,
        },
      );

      final data =
          response.data;

      if (data is! Map) {
        throw const ServerException(
          'Сервер вернул некорректный ответ обновления токена.',
        );
      }

      final newAccessToken =
          data['accessToken']
              ?.toString();

      final newRefreshToken =
          data['refreshToken']
              ?.toString();

      final expiresIn =
          int.tryParse(
        data['expiresIn']
                ?.toString() ??
            '',
      );

      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty ||
          expiresIn == null) {
        throw const ServerException(
          'Ответ сервера не содержит новые токены.',
        );
      }

      _session.updateTokens(
        accessToken:
            newAccessToken,
        refreshToken:
            newRefreshToken,
        expiresIn:
            expiresIn,
      );

      final userData =
          data['user'];

      if (userData is Map) {
        _session.setUser(
          AppUser.fromJson(
            Map<String, dynamic>.from(
              userData,
            ),
          ),
        );
      }

      await _session
          .persistTokens();
    });
  }

  Future<void>
      restoreSession() async {
    await _session
        .restoreTokens();

    if (!_session.hasTokens) {
      return;
    }

    try {
      await me();
      return;
    } on UnauthorizedException {
      // Access token истёк.
      // Ниже пробуем refresh.
    } on NetworkException {
      // Сервер недоступен.
      // Сохранённую сессию сразу
      // не удаляем.
      return;
    } on ServerException {
      return;
    }

    try {
      await refresh();
      await me();
    } catch (_) {
      await clearSession();
    }
  }

  Future<void> logout() async {
    final refreshToken =
        _session.refreshToken;

    try {
      if (refreshToken != null &&
          refreshToken.isNotEmpty) {
        await guard(() async {
          await _dio.post(
            '/auth/logout',
            data: {
              'refreshToken':
                  refreshToken,
            },
          );
        });
      }
    } finally {
      await clearSession();
    }
  }

  Future<void>
      clearSession() async {
    _session.clear();

    await _session
        .clearPersistentData();
  }
}