abstract class LoanRepository {
  Future<void> issue({
    required int readerId,
    required int bookId,
    int days = 14,
  });
}