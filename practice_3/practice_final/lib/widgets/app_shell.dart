import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/auth_models.dart';
import '../models/entity_schema.dart';
import '../state/auth_controller.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AppShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  List<_NavItem> _items(UserRole role) {
    final items = <_NavItem>[
      const _NavItem(
        label: 'Главная',
        route: '/dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
      ),
    ];

    for (final schema in entitySchemas.values) {
      if (schema.ownerRole == role) {
        items.add(
          _NavItem(
            label: schema.title,
            route: '/data/${schema.collection}',
            icon: schema.icon,
            selectedIcon: schema.icon,
          ),
        );
      }
    }
    return items;
  }

  int _selectedIndex(List<_NavItem> items) {
    for (var i = 0; i < items.length; i++) {
      if (currentPath.startsWith(items[i].route)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    if (user == null) {
      return child;
    }

    final items = _items(user.role);
    final selectedIndex = _selectedIndex(items);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 600;
        final expanded = width >= 1200;

        Widget content = child;
        if (width >= 1600) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: child,
            ),
          );
        }

        if (compact) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Инженерные расчёты'),
              actions: [
                PopupMenuButton<String>(
                  tooltip: 'Профиль',
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await auth.logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Text('${user.name}\n${user.role.title}'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Выйти'),
                    ),
                  ],
                ),
              ],
            ),
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              onDestinationSelected: (index) => context.go(items[index].route),
              destinations: items
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                extended: expanded,
                minExtendedWidth: 230,
                onDestinationSelected: (index) => context.go(items[index].route),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      const Icon(Icons.architecture, size: 34),
                      if (expanded) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'CAE Manager',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: expanded
                      ? SizedBox(
                          width: 210,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                user.role.title,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await auth.logout();
                                  if (context.mounted) {
                                    context.go('/login');
                                  }
                                },
                                icon: const Icon(Icons.logout, size: 18),
                                label: const Text('Выйти'),
                              ),
                            ],
                          ),
                        )
                      : IconButton(
                          tooltip: 'Выйти',
                          onPressed: () async {
                            await auth.logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          icon: const Icon(Icons.logout),
                        ),
                ),
                destinations: items
                    .map(
                      (item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
  });
}
