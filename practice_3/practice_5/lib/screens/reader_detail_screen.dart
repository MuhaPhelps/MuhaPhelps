import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/reader.dart';
import '../state/reader_list_notifier.dart';

class ReaderDetailScreen
    extends StatefulWidget {
  final int readerId;

  const ReaderDetailScreen({
    super.key,
    required this.readerId,
  });

  @override
  State<ReaderDetailScreen>
      createState() =>
          _ReaderDetailScreenState();
}

class _ReaderDetailScreenState
    extends State<ReaderDetailScreen> {
  Future<Reader?>? _readerFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _readerFuture ??= context
        .read<ReaderListNotifier>()
        .findById(
          widget.readerId,
        );
  }

  @override
  void didUpdateWidget(
    covariant ReaderDetailScreen oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.readerId !=
        widget.readerId) {
      _readerFuture = context
          .read<ReaderListNotifier>()
          .findById(
            widget.readerId,
          );
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/readers');
    }
  }

  String _formatDate(
    DateTime? value,
  ) {
    if (value == null) {
      return 'Не указана';
    }

    final day =
        value.day
            .toString()
            .padLeft(2, '0');

    final month =
        value.month
            .toString()
            .padLeft(2, '0');

    return '$day.$month.${value.year}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: _goBack,
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
        title: const Text(
          'Карточка читателя',
        ),
      ),
      body: FutureBuilder<Reader?>(
        future: _readerFuture,
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot
                  .connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: '
                '${snapshot.error}',
              ),
            );
          }

          final reader =
              snapshot.data;

          if (reader == null) {
            return const Center(
              child: Text(
                'Читатель не найден',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            );
          }

          return Center(
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                24,
              ),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 700,
                ),
                child: Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 32,
                              child: Icon(
                                Icons.person,
                                size: 36,
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: Text(
                                reader.fullName,
                                style:
                                    Theme.of(
                                  context,
                                )
                                        .textTheme
                                        .headlineMedium,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        const Text(
                          'Данные читателя',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        _DetailRow(
                          label: 'ID',
                          value:
                              '${reader.id}',
                        ),

                        _DetailRow(
                          label: 'ФИО',
                          value:
                              reader.fullName,
                        ),

                        _DetailRow(
                          label: 'Email',
                          value:
                              reader.email,
                        ),

                        _DetailRow(
                          label: 'Телефон',
                          value:
                              reader.phone,
                        ),

                        _DetailRow(
                          label: 'Статус',
                          value:
                              reader.isDeleted
                                  ? 'Удалён'
                                  : 'Активен',
                        ),

                        const Divider(
                          height: 40,
                        ),

                        const Text(
                          'Читательский билет',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        _DetailRow(
                          label:
                              'ID билета',
                          value:
                              '${reader.card.id}',
                        ),

                        _DetailRow(
                          label:
                              'Номер билета',
                          value:
                              reader.card.number,
                        ),

                        _DetailRow(
                          label:
                              'Дата выдачи',
                          value:
                              _formatDate(
                            reader
                                .card
                                .issuedAt,
                          ),
                        ),

                        _DetailRow(
                          label:
                              'Действителен до',
                          value:
                              _formatDate(
                            reader
                                .card
                                .expiresAt,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}