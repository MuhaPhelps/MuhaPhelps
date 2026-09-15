import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
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

      // Коды 4xx разбираем самостоятельно.
      // Ошибки 5xx попадут в onError.
      validateStatus: (status) {
        return status != null &&
            status < 500;
      },
    ),
  );

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

        // Номер текущей попытки.
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
      ) {
        final status =
            response.statusCode ?? 0;

        if (kDebugMode) {
          debugPrint(
            '[API] <-- '
            '${response.requestOptions.method} '
            '${response.requestOptions.uri} '
            '[$status]',
          );
        }

        // Из-за validateStatus ответы 4xx
        // приходят сюда.
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions:
                  response
                      .requestOptions,
              response: response,
              type:
                  DioExceptionType
                      .badResponse,
              error: mapHttpError(
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

        if (_shouldRetry(error)) {
          final currentAttempt =
              options.extra[
                      'retryAttempt']
                  as int? ??
              1;

          // Максимум 3 попытки всего:
          // 1 исходная + 2 повтора.
          if (currentAttempt < 3) {
            final nextAttempt =
                currentAttempt + 1;

            options.extra[
                    'retryAttempt'] =
                nextAttempt;

            // Нарастающая пауза:
            // перед второй попыткой 400 мс,
            // перед третьей 800 мс.
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
              final response =
                  await dio.fetch<dynamic>(
                options,
              );

              return handler.resolve(
                response,
              );
            } on DioException catch (retryError) {
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
  // POST, PUT, DELETE повторять опасно.
  if (method != 'GET') {
    return false;
  }

  // Отменённый поисковый запрос
  // повторять нельзя.
  if (error.type ==
      DioExceptionType.cancel) {
    return false;
  }

  // Ошибка соединения.
  if (error.type ==
      DioExceptionType
          .connectionError) {
    return true;
  }

  // Таймаут.
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

  // Серверные ошибки 5xx.
  final status =
      error.response?.statusCode;

  if (status != null &&
      status >= 500) {
    return true;
  }

  return false;
}