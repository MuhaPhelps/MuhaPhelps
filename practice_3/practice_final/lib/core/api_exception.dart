import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, String> fieldErrors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    var message = 'Не удалось выполнить запрос к серверу';
    final fieldErrors = <String, String>{};

    if (data is Map<String, dynamic>) {
      final rawMessage = data['message'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        message = rawMessage;
      }

      final rawData = data['data'];
      if (rawData is Map) {
        for (final entry in rawData.entries) {
          final value = entry.value;
          if (value is Map && value['message'] is String) {
            fieldErrors['${entry.key}'] = '${value['message']}';
          }
        }
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      message = 'Сервер не ответил вовремя';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Сервер недоступен. Проверьте, что PocketBase запущен.';
    }

    return ApiException(
      statusCode: response?.statusCode,
      message: message,
      fieldErrors: fieldErrors,
    );
  }

  @override
  String toString() => message;
}
