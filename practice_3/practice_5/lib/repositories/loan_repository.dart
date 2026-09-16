import '../models/loan.dart';

abstract class LoanRepository {
  Future<List<Loan>> getAll();

  Future<void> issue({
    required int readerId,
    required int bookId,
    int days = 14,
  });
}