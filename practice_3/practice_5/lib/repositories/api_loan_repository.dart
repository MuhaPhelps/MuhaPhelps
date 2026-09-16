import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/loan.dart';
import 'loan_repository.dart';

class ApiLoanRepository
    implements LoanRepository {
  final Dio _dio;

  ApiLoanRepository(
    this._dio,
  );

  @override
  Future<List<Loan>> getAll() {
    return guard(
      () async {
        final response =
            await _dio.get(
          '/loans',
          queryParameters: {
            'size': 100,
          },
        );

        final data =
            response.data;

        if (data is! Map) {
          throw StateError(
            'Сервер вернул некорректный список выдач.',
          );
        }

        final rawItems =
            data['items'];

        if (rawItems is! List) {
          throw StateError(
            'В ответе сервера отсутствует список выдач.',
          );
        }

        return rawItems
            .whereType<Map>()
            .map(
              (item) =>
                  Loan.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
            )
            .toList();
      },
    );
  }

  @override
  Future<void> issue({
    required int readerId,
    required int bookId,
    int days = 14,
  }) {
    return guard(
      () async {
        await _dio.post(
          '/loans',
          data: {
            'readerId': readerId,
            'bookId': bookId,
            'days': days,
          },
        );
      },
    );
  }
}