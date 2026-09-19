import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'config.dart';

class ApiClient {
  final String? Function() tokenProvider;
  late final Dio dio;

  ApiClient({required this.tokenProvider}) {
    dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = token;
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
  }) async {
    try {
      final response = await dio.post<dynamic>(path, data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
  }) async {
    try {
      final response = await dio.patch<dynamic>(path, data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> delete(String path) async {
    try {
      await dio.delete<dynamic>(path);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
