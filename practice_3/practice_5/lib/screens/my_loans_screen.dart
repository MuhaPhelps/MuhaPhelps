import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loan.dart';
import '../repositories/loan_repository.dart';

class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({
    super.key,
  });

  @override
  State<MyLoansScreen> createState() =>
      _MyLoansScreenState();
}

class _MyLoansScreenState
    extends State<MyLoansScreen> {
  bool _isLoading = true;
  String? _error;
  List<Loan> _loans = [];

  @override
  void initState() {
    super.initState();

    Future.microtask(
      _load,
    );
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository =
          context.read<LoanRepository>();

      final loans =
          await repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _loans = loans;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Не удалось загрузить выдачи.\n$error';

        _isLoading = false;
      });
    }
  }

  String _formatDate(
    DateTime date,
  ) {
    final local =
        date.toLocal();

    final day =
        local.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        local.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day.$month.${local.year}';
  }

  String _statusTitle(
    Loan loan,
  ) {
    if (loan.isReturned) {
      return 'Возвращена';
    }

    if (loan.isOverdue) {
      return 'Просрочена';
    }

    return 'Активна';
  }

  IconData _statusIcon(
    Loan loan,
  ) {
    if (loan.isReturned) {
      return Icons.check_circle_outline;
    }

    if (loan.isOverdue) {
      return Icons.warning_amber_rounded;
    }

    return Icons.schedule;
  }

  Color _statusColor(
    BuildContext context,
    Loan loan,
  ) {
    if (loan.isReturned) {
      return Colors.green;
    }

    if (loan.isOverdue) {
      return Theme.of(
        context,
      ).colorScheme.error;
    }

    return Theme.of(
      context,
    ).colorScheme.primary;
  }

  Widget _buildLoanCard(
    BuildContext context,
    Loan loan,
  ) {
    final statusColor =
        _statusColor(
      context,
      loan,
    );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    loan.bookTitle,
                    style:
                        Theme.of(
                      context,
                    ).textTheme.titleMedium
                            ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        statusColor
                            .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(
                          loan,
                        ),
                        size: 17,
                        color:
                            statusColor,
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      Text(
                        _statusTitle(
                          loan,
                        ),
                        style:
                            TextStyle(
                          color:
                              statusColor,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            _InfoRow(
              icon:
                  Icons.calendar_today_outlined,
              label:
                  'Дата выдачи',
              value:
                  _formatDate(
                loan.issuedAt,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            _InfoRow(
              icon:
                  Icons.event_outlined,
              label:
                  'Вернуть до',
              value:
                  _formatDate(
                loan.dueAt,
              ),
            ),

            if (loan.returnedAt !=
                null) ...[
              const SizedBox(
                height: 8,
              ),

              _InfoRow(
                icon:
                    Icons.assignment_turned_in_outlined,
                label:
                    'Дата возврата',
                value:
                    _formatDate(
                  loan.returnedAt!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Мои выдачи',
        ),
        actions: [
          IconButton(
            tooltip:
                'Обновить',
            onPressed:
                _isLoading
                    ? null
                    : _load,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body:
          _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : _error != null
                  ? Center(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets.all(
                          24,
                        ),
                        child:
                            Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            Text(
                              _error!,
                              textAlign:
                                  TextAlign.center,
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            FilledButton.icon(
                              onPressed:
                                  _load,
                              icon:
                                  const Icon(
                                Icons.refresh,
                              ),
                              label:
                                  const Text(
                                'Повторить',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _loans.isEmpty
                      ? const Center(
                          child:
                              Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.library_books_outlined,
                                size: 64,
                              ),
                              SizedBox(
                                height: 16,
                              ),
                              Text(
                                'У вас пока нет выдач',
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh:
                              _load,
                          child:
                              ListView.builder(
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),
                            itemCount:
                                _loans.length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              return _buildLoanCard(
                                context,
                                _loans[index],
                              );
                            },
                          ),
                        ),
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color:
              Theme.of(
            context,
          ).colorScheme.onSurfaceVariant,
        ),

        const SizedBox(
          width: 10,
        ),

        Text(
          '$label: ',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w500,
          ),
        ),

        Expanded(
          child: Text(
            value,
          ),
        ),
      ],
    );
  }
}