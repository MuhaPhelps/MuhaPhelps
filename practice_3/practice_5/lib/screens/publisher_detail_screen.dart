import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/publisher.dart';
import '../state/publisher_list_notifier.dart';

class PublisherDetailScreen
    extends StatefulWidget {
  final int publisherId;

  const PublisherDetailScreen({
    super.key,
    required this.publisherId,
  });

  @override
  State<PublisherDetailScreen> createState() =>
      _PublisherDetailScreenState();
}

class _PublisherDetailScreenState
    extends State<PublisherDetailScreen> {
  Future<Publisher?>? _publisherFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _publisherFuture ??= context
        .read<PublisherListNotifier>()
        .findById(widget.publisherId);
  }

  @override
  void didUpdateWidget(
    covariant PublisherDetailScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.publisherId !=
        widget.publisherId) {
      _publisherFuture = context
          .read<PublisherListNotifier>()
          .findById(widget.publisherId);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/publishers');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Карточка издательства',
        ),
      ),
      body: FutureBuilder<Publisher?>(
        future: _publisherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: ${snapshot.error}',
              ),
            );
          }

          final publisher = snapshot.data;

          if (publisher == null) {
            return const Center(
              child: Text(
                'Издательство не найдено',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 650,
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 32,
                              child: Icon(
                                Icons.business,
                                size: 34,
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: Text(
                                publisher.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _DetailRow(
                          label: 'ID',
                          value:
                              '${publisher.id}',
                        ),
                        _DetailRow(
                          label: 'Название',
                          value:
                              publisher.name,
                        ),
                        _DetailRow(
                          label: 'Город',
                          value:
                              publisher.city,
                        ),
                        _DetailRow(
                          label:
                              'Год основания',
                          value: publisher
                                  .foundedYear
                                  ?.toString() ??
                              'Не указан',
                        ),
                        _DetailRow(
                          label: 'Статус',
                          value:
                              publisher.isDeleted
                                  ? 'Удалено'
                                  : 'Активно',
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
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