import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Нет соединения, таймаут,
/// сервер недоступен или запрос заблокирован CORS.
class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'Сервер недоступен. Проверьте соединение.',
  ]);
}

/// 401 — пользователь не авторизован.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message =
        'Требуется вход в систему.',
  ]);
}

/// 403 — недостаточно прав.
class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message =
        'Недостаточно прав для этого действия.',
  ]);
}

/// 404 — запись не найдена.
class NotFoundException extends ApiException {
  const NotFoundException([
    super.message =
        'Запись не найдена.',
  ]);
}

/// 409 — конфликт данных.
class ConflictException extends ApiException {
  const ConflictException(
    super.message,
  );
}

/// 422 — серверная валидация.
///
/// errors содержит ошибки отдельных полей,
/// например:
///
/// {
///   'isbn': 'Книга с таким ISBN уже существует'
/// }
class ValidationException extends ApiException {
  final Map<String, String> errors;

  const ValidationException(
    super.message,
    this.errors,
  );
}

/// Ошибки сервера 5xx.
class ServerException extends ApiException {
  const ServerException([
    super.message =
        'Ошибка на сервере. Попробуйте позже.',
  ]);
}

ApiException mapHttpError(
  int status,
  dynamic body,
) {
  String? message;

  if (body is Map &&
      body['message'] is String) {
    message =
        body['message'] as String;
  }

  switch (status) {
    case 401:
      return UnauthorizedException(
        message ??
            'Требуется вход в систему.',
      );

    case 403:
      return ForbiddenException(
        message ??
            'Недостаточно прав для этого действия.',
      );

    case 404:
      return NotFoundException(
        message ??
            'Запись не найдена.',
      );

    case 409:
      return ConflictException(
        message ??
            'Операция невозможна из-за конфликта данных.',
      );

    case 422:
      final errors =
          <String, String>{};

      if (body is Map &&
          body['errors'] is Map) {
        final rawErrors =
            body['errors'] as Map;

        for (final entry
            in rawErrors.entries) {
          errors[
              entry.key.toString()] =
              entry.value.toString();
        }
      }

      return ValidationException(
        message ??
            'Ошибка валидации',
        errors,
      );

    default:
      return ServerException(
        message ??
            'Ошибка сервера (код $status).',
      );
  }
}

ApiException mapDioError(
  DioException error,
) {
  // Если ошибка уже была преобразована
  // нашим интерсептором, используем её.
  final existing =
      error.error;

  if (existing is ApiException) {
    return existing;
  }

  // Если сервер всё-таки прислал HTTP-ответ,
  // разбираем его код.
  final response =
      error.response;

  if (response != null &&
      response.statusCode != null) {
    return mapHttpError(
      response.statusCode!,
      response.data,
    );
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkException(
        'Сервер не ответил вовремя.',
      );

    case DioExceptionType.connectionError:
      return const NetworkException(
        'Не удалось соединиться с сервером. '
        'Если сервер запущен, проверьте Console '
        'браузера на наличие ошибки CORS.',
      );

    case DioExceptionType.cancel:
      return const NetworkException(
        'Запрос отменён.',
      );

    default:
      return const ServerException();
  }
}

/// Обёртка для сетевых операций.
///
/// DioException наружу из репозитория
/// выходить не должен.
Future<T> guard<T>(
  Future<T> Function() action,
) async {
  try {
    return await action();
  } on DioException catch (error) {
    throw mapDioError(error);
  }
}