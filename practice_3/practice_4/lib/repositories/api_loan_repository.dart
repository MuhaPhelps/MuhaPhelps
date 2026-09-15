import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import 'loan_repository.dart';

class ApiLoanRepository
    implements LoanRepository {
  final Dio _dio;

  ApiLoanRepository(
    this._dio,
  );

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