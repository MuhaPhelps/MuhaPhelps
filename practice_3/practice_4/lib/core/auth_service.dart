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

  Future<void> login({
    required String username,
    required String password,
  }) {
    return guard(
      () async {
        final response =
            await _dio.post(
          '/auth/login',
          data: {
            'username': username,
            'password': password,
          },
        );

        final data =
            Map<String, dynamic>.from(
          response.data as Map,
        );

        final accessToken =
            data['accessToken']
                    ?.toString() ??
                '';

        final refreshToken =
            data['refreshToken']
                    ?.toString() ??
                '';

        final expiresIn =
            _toInt(
          data['expiresIn'],
          fallback: 900,
        );

        if (accessToken.isEmpty ||
            refreshToken.isEmpty) {
          throw const ServerException(
            'Сервер не вернул токены авторизации.',
          );
        }

        _session.updateTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: expiresIn,
        );
      },
    );
  }

  Future<void> refresh() {
    final refreshToken =
        _session.refreshToken;

    if (refreshToken == null ||
        refreshToken.isEmpty) {
      throw const UnauthorizedException(
        'Токен обновления отсутствует.',
      );
    }

    return guard(
      () async {
        final response =
            await _dio.post(
          '/auth/refresh',
          data: {
            'refreshToken':
                refreshToken,
          },
        );

        final data =
            Map<String, dynamic>.from(
          response.data as Map,
        );

        final newAccessToken =
            data['accessToken']
                    ?.toString() ??
                '';

        final newRefreshToken =
            data['refreshToken']
                    ?.toString() ??
                '';

        final expiresIn =
            _toInt(
          data['expiresIn'],
          fallback: 900,
        );

        if (newAccessToken.isEmpty ||
            newRefreshToken.isEmpty) {
          throw const ServerException(
            'Сервер не вернул новые токены.',
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
      },
    );
  }

  Future<void> logout() async {
    final refreshToken =
        _session.refreshToken;

    if (refreshToken == null ||
        refreshToken.isEmpty) {
      _session.clear();
      return;
    }

    try {
      await guard(
        () async {
          await _dio.post(
            '/auth/logout',
            data: {
              'refreshToken':
                  refreshToken,
            },
          );
        },
      );
    } finally {
      _session.clear();
    }
  }

  int _toInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }
}