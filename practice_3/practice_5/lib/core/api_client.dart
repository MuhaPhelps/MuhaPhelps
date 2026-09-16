import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  Future<void> Function()? refreshToken,
  Future<void> Function()? onRefreshFailed,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(
        seconds: 10,
      ),
      receiveTimeout: const Duration(
        seconds: 15,
      ),
      headers: {
        'Content-Type': 'application/json',
      },

      // Ответы 4xx разбираем сами.
      // 5xx попадут в onError.
      validateStatus: (status) {
        return status != null &&
            status < 500;
      },
    ),
  );

  // Одновременно может прийти несколько 401.
  // В таком случае refresh выполняем только один раз.
  Future<void>? refreshFuture;

  Future<void> refreshOnce() async {
    final running =
        refreshFuture;

    if (running != null) {
      await running;
      return;
    }

    final callback =
        refreshToken;

    if (callback == null) {
      throw StateError(
        'Обновление токена не настроено.',
      );
    }

    final future =
        callback();

    refreshFuture =
        future;

    try {
      await future;
    } finally {
      if (identical(
        refreshFuture,
        future,
      )) {
        refreshFuture = null;
      }
    }
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (
        options,
        handler,
      ) {
        final token =
            tokenProvider?.call();

        if (token != null &&
            token.isNotEmpty) {
          options.headers[
                  'Authorization'] =
              'Bearer $token';
        }

        options.extra.putIfAbsent(
          'retryAttempt',
          () => 1,
        );

        if (kDebugMode) {
          debugPrint(
            '[API] --> '
            '${options.method} '
            '${options.uri}',
          );
        }

        return handler.next(
          options,
        );
      },

      onResponse: (
        response,
        handler,
      ) async {
        final status =
            response.statusCode ?? 0;

        final options =
            response.requestOptions;

        if (kDebugMode) {
          debugPrint(
            '[API] <-- '
            '${options.method} '
            '${options.uri} '
            '[$status]',
          );
        }

        // ========================================
        // 401 -> REFRESH -> ПОВТОР ЗАПРОСА
        // ========================================

        final isAuthRequest =
            options.path.contains(
          '/auth/',
        );

        final alreadyRetried =
            options.extra[
                    'authRetried'] ==
                true;

        if (status == 401 &&
            !isAuthRequest &&
            !alreadyRetried &&
            refreshToken != null) {
          if (kDebugMode) {
            debugPrint(
              '[AUTH] access token истёк, '
              'выполняем refresh',
            );
          }

          try {
            await refreshOnce();
          } catch (refreshError) {
            if (kDebugMode) {
              debugPrint(
                '[AUTH] refresh не удался: '
                '$refreshError',
              );
            }

            try {
              await onRefreshFailed
                  ?.call();
            } catch (_) {
              // Ошибку очистки сессии
              // дополнительно не пробрасываем.
            }

            return handler.reject(
              DioException(
                requestOptions:
                    options,
                response:
                    response,
                type:
                    DioExceptionType
                        .badResponse,
                error:
                    mapHttpError(
                  status,
                  response.data,
                ),
              ),
              true,
            );
          }

          // Не позволяем этому же запросу
          // запускать второй refresh.
          options.extra[
                  'authRetried'] =
              true;

          final newToken =
              tokenProvider?.call();

          if (newToken != null &&
              newToken.isNotEmpty) {
            options.headers[
                    'Authorization'] =
                'Bearer $newToken';
          } else {
            options.headers.remove(
              'Authorization',
            );
          }

          if (kDebugMode) {
            debugPrint(
              '[AUTH] токен обновлён, '
              'повторяем '
              '${options.method} '
              '${options.uri}',
            );
          }

          try {
            final repeatedResponse =
                await dio.fetch<dynamic>(
              options,
            );

            return handler.resolve(
              repeatedResponse,
            );
          } on DioException catch (
            repeatedError
          ) {
            return handler.reject(
              repeatedError,
              true,
            );
          }
        }

        // Даже после успешного refresh
        // сервер снова ответил 401.
        // Зацикливаться нельзя.
        if (status == 401 &&
            !isAuthRequest &&
            alreadyRetried) {
          if (kDebugMode) {
            debugPrint(
              '[AUTH] повторный запрос '
              'снова вернул 401. '
              'Сессия завершается.',
            );
          }

          try {
            await onRefreshFailed
                ?.call();
          } catch (_) {
            // Не мешаем обработке
            // исходной ошибки.
          }
        }

        // ========================================
        // ОСТАЛЬНЫЕ 4xx
        // ========================================

        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions:
                  options,
              response:
                  response,
              type:
                  DioExceptionType
                      .badResponse,
              error:
                  mapHttpError(
                status,
                response.data,
              ),
            ),
            true,
          );
        }

        return handler.next(
          response,
        );
      },

      onError: (
        error,
        handler,
      ) async {
        final options =
            error.requestOptions;

        if (kDebugMode) {
          debugPrint(
            '[API] сбой '
            '${options.uri}: '
            '${error.type}',
          );
        }

        // ========================================
        // RETRY ИЗ ПР4
        // ========================================

        if (_shouldRetry(
          error,
        )) {
          final currentAttempt =
              options.extra[
                      'retryAttempt']
                  as int? ??
              1;

          // Всего максимум три попытки:
          // исходная + два повтора.
          if (currentAttempt < 3) {
            final nextAttempt =
                currentAttempt + 1;

            options.extra[
                    'retryAttempt'] =
                nextAttempt;

            final delay =
                Duration(
              milliseconds:
                  400 *
                      (nextAttempt -
                          1),
            );

            if (kDebugMode) {
              debugPrint(
                '[API] повтор '
                '$nextAttempt/3 '
                '${options.method} '
                '${options.uri} '
                'через '
                '${delay.inMilliseconds} мс',
              );
            }

            await Future.delayed(
              delay,
            );

            try {
              final repeatedResponse =
                  await dio.fetch<dynamic>(
                options,
              );

              return handler.resolve(
                repeatedResponse,
              );
            } on DioException catch (
              retryError
            ) {
              return handler.next(
                retryError,
              );
            }
          }
        }

        return handler.next(
          error,
        );
      },
    ),
  );

  return dio;
}

bool _shouldRetry(
  DioException error,
) {
  final method =
      error.requestOptions.method
          .toUpperCase();

  // Повторяем только GET.
  if (method != 'GET') {
    return false;
  }

  // CancelToken — это намеренная отмена,
  // её повторять нельзя.
  if (error.type ==
      DioExceptionType.cancel) {
    return false;
  }

  if (error.type ==
      DioExceptionType
          .connectionError) {
    return true;
  }

  if (error.type ==
          DioExceptionType
              .connectionTimeout ||
      error.type ==
          DioExceptionType
              .sendTimeout ||
      error.type ==
          DioExceptionType
              .receiveTimeout) {
    return true;
  }

  final status =
      error.response
          ?.statusCode;

  if (status != null &&
      status >= 500) {
    return true;
  }

  return false;
}