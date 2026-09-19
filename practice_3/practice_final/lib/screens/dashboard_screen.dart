import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/entity_schema.dart';
import '../state/auth_controller.dart';
import '../widgets/page_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user!;
    final allowed = entitySchemas.values
        .where((schema) => schema.ownerRole == user.role)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Здравствуйте, ${user.name}',
            subtitle: 'Роль: ${user.role.title}. Выберите рабочий раздел.',
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1000
                    ? 3
                    : constraints.maxWidth >= 600
                        ? 2
                        : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: allowed.length,
                  itemBuilder: (context, index) {
                    final schema = allowed[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.go('/data/${schema.collection}'),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(schema.icon, size: 42),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  schema.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Предметная область',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Система хранит заказчиков, инженеров, проекты, материалы, '
                      'сечения, нагрузки, инженерные расчёты и результаты проверки. '
                      'Связи между сущностями используются непосредственно в формах.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
