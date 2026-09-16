import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/system_user.dart';
import 'user_repository.dart';

class ApiUserRepository
    implements UserRepository {
  final Dio _dio;

  ApiUserRepository(
    this._dio,
  );

  @override
  Future<List<SystemUser>> getAll() {
    return guard(
      () async {
        final response =
            await _dio.get(
          '/users',
          queryParameters: {
            'size': 100,
          },
        );

        final data =
            response.data;

        if (data is! Map) {
          throw StateError(
            'Сервер вернул некорректный список пользователей.',
          );
        }

        final rawItems =
            data['items'];

        if (rawItems is! List) {
          throw StateError(
            'В ответе сервера отсутствует список пользователей.',
          );
        }

        return rawItems
            .whereType<Map>()
            .map(
              (item) =>
                  SystemUser.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
            )
            .toList();
      },
    );
  }
}