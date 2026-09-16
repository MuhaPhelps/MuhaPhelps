import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/auth_service.dart';
import '../core/auth_session.dart';
import '../core/role_permissions.dart';

class LibraryShell extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const LibraryShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  bool get _isFormRoute {
    if (currentPath.endsWith('/new')) {
      return true;
    }

    return RegExp(
      r'^/(books|authors|genres|publishers|readers)/\d+/edit$',
    ).hasMatch(currentPath);
  }

  List<_NavigationItem> _navigationItems(
    AuthSession session,
  ) {
    final role = session.role;

    if (role == null) {
      return const [];
    }

    final items = <_NavigationItem>[
      const _NavigationItem(
        route: '/books',
        label: 'Книги',
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book,
      ),
    ];

    // Читатель видит свои выдачи.
    if (role.can(
      AppPermission.viewOwnLoans,
    )) {
      items.add(
        const _NavigationItem(
          route: '/my-loans',
          label: 'Мои выдачи',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
        ),
      );
    }

    // Библиотекарь и администратор
    // работают со справочниками.
    if (role.can(
      AppPermission.manageDictionaries,
    )) {
      items.addAll(
        const [
          _NavigationItem(
            route: '/authors',
            label: 'Авторы',
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
          ),
          _NavigationItem(
            route: '/genres',
            label: 'Жанры',
            icon: Icons.category_outlined,
            selectedIcon: Icons.category,
          ),
          _NavigationItem(
            route: '/publishers',
            label: 'Издательства',
            icon: Icons.business_outlined,
            selectedIcon: Icons.business,
          ),
        ],
      );
    }

    // Библиотекарь и администратор
    // работают с читателями.
    if (role.can(
      AppPermission.manageReaders,
    )) {
      items.add(
        const _NavigationItem(
          route: '/readers',
          label: 'Читатели',
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge,
        ),
      );
    }

    // Только администратор.
    if (role.can(
      AppPermission.manageUsers,
    )) {
      items.add(
        const _NavigationItem(
          route: '/admin/users',
          label: 'Пользователи',
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts,
        ),
      );
    }

    return items;
  }

  int _selectedIndex(
    List<_NavigationItem> items,
  ) {
    for (var i = 0; i < items.length; i++) {
      if (currentPath.startsWith(
        items[i].route,
      )) {
        return i;
      }
    }

    return 0;
  }

  void _navigate(
    BuildContext context,
    List<_NavigationItem> items,
    int index,
  ) {
    if (index < 0 ||
        index >= items.length) {
      return;
    }

    final target =
        items[index].route;

    if (currentPath == target) {
      return;
    }

    context.go(
      target,
    );
  }

  Future<void> _logout(
    BuildContext context,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Выход из системы',
          ),
          content: const Text(
            'Вы действительно хотите выйти?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Отмена',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Выйти',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final authService =
        context.read<AuthService>();

    try {
      await authService.logout();
    } catch (_) {
      // Даже если сервер недоступен,
      // локальная сессия будет очищена.
    }
  }

  Widget _createButton({
    required BuildContext context,
    required String path,
    required String label,
  }) {
    return FloatingActionButton.extended(
      onPressed: () {
        context.push(path);
      },
      icon: const Icon(
        Icons.add,
      ),
      label: Text(
        label,
      ),
    );
  }

  Widget _editButton({
    required BuildContext context,
    required String path,
  }) {
    return FloatingActionButton.extended(
      onPressed: () {
        context.push(path);
      },
      icon: const Icon(
        Icons.edit,
      ),
      label: const Text(
        'Редактировать',
      ),
    );
  }

  Widget? _buildFloatingButton(
    BuildContext context,
    AuthSession session,
  ) {
    final role =
        session.role;

    if (role == null) {
      return null;
    }

    if (currentPath == '/books') {
      if (!role.can(
        AppPermission.manageBooks,
      )) {
        return null;
      }

      return _createButton(
        context: context,
        path: '/books/new',
        label: 'Добавить книгу',
      );
    }

    if (currentPath == '/authors') {
      if (!role.can(
        AppPermission.manageDictionaries,
      )) {
        return null;
      }

      return _createButton(
        context: context,
        path: '/authors/new',
        label: 'Добавить автора',
      );
    }

    if (currentPath == '/genres') {
      if (!role.can(
        AppPermission.manageDictionaries,
      )) {
        return null;
      }

      return _createButton(
        context: context,
        path: '/genres/new',
        label: 'Добавить жанр',
      );
    }

    if (currentPath == '/publishers') {
      if (!role.can(
        AppPermission.manageDictionaries,
      )) {
        return null;
      }

      return _createButton(
        context: context,
        path: '/publishers/new',
        label: 'Добавить издательство',
      );
    }

    if (currentPath == '/readers') {
      if (!role.can(
        AppPermission.manageReaders,
      )) {
        return null;
      }

      return _createButton(
        context: context,
        path: '/readers/new',
        label: 'Добавить читателя',
      );
    }

    final bookMatch =
        RegExp(
      r'^/books/(\d+)$',
    ).firstMatch(
      currentPath,
    );

    if (bookMatch != null) {
      if (!role.can(
        AppPermission.manageBooks,
      )) {
        return null;
      }

      return _editButton(
        context: context,
        path:
            '/books/${bookMatch.group(1)}/edit',
      );
    }

    final authorMatch =
        RegExp(
      r'^/authors/(\d+)$',
    ).firstMatch(
      currentPath,
    );

    if (authorMatch != null) {
      if (!role.can(
        AppPermission.manageDictionaries,
      )) {
        return null;
      }

      return _editButton(
        context: context,
        path:
            '/authors/${authorMatch.group(1)}/edit',
      );
    }

    final genreMatch =
        RegExp(
      r'^/genres/(\d+)$',
    ).firstMatch(
      currentPath,
    );

    if (genreMatch != null) {
      if (!role.can(
        AppPermission.manageDictionaries,
      )) {
        return null;
      }

      return _editButton(
        context: context,
        path:
            '/genres/${genreMatch.group(1)}/edit',
      );
    }

    final publisherMatch =
        RegExp(
      r'^/publishers/(\d+)$',
    ).firstMatch(
      currentPath,
    );

    if (publisherMatch != null) {
      if (!role.can(
        AppPermission.manageDictionaries,
      )) {
        return null;
      }

      return _editButton(
        context: context,
        path:
            '/publishers/${publisherMatch.group(1)}/edit',
      );
    }

    final readerMatch =
        RegExp(
      r'^/readers/(\d+)$',
    ).firstMatch(
      currentPath,
    );

    if (readerMatch != null) {
      if (!role.can(
        AppPermission.manageReaders,
      )) {
        return null;
      }

      return _editButton(
        context: context,
        path:
            '/readers/${readerMatch.group(1)}/edit',
      );
    }

    return null;
  }

  Widget _buildUserInfo(
    BuildContext context,
    AuthSession session,
  ) {
    final user =
        session.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.all(
        12,
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          CircleAvatar(
            child: Text(
              user.name.isNotEmpty
                  ? user.name[0]
                      .toUpperCase()
                  : '?',
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          SizedBox(
            width: 150,
            child: Text(
              session.userDisplayName,
              textAlign:
                  TextAlign.center,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            session.role?.title ??
                user.role.title,
            textAlign:
                TextAlign.center,
            style:
                Theme.of(
              context,
            ).textTheme.bodySmall,
          ),

          const SizedBox(
            height: 8,
          ),

          OutlinedButton.icon(
            onPressed: () {
              _logout(
                context,
              );
            },
            icon: const Icon(
              Icons.logout,
              size: 18,
            ),
            label: const Text(
              'Выйти',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileUserBar(
    BuildContext context,
    AuthSession session,
  ) {
    final user =
        session.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 1,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Text(
                user.name.isNotEmpty
                    ? user.name[0]
                        .toUpperCase()
                    : '?',
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    session.userDisplayName,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  Text(
                    session.role?.title ??
                        user.role.title,
                    style:
                        Theme.of(
                      context,
                    ).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            IconButton(
              tooltip:
                  'Выйти из системы',
              onPressed: () {
                _logout(
                  context,
                );
              },
              icon: const Icon(
                Icons.logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final authSession =
        context.watch<AuthSession>();

    if (_isFormRoute) {
      return child;
    }

    final navigationItems =
        _navigationItems(
      authSession,
    );

    final selectedIndex =
        _selectedIndex(
      navigationItems,
    );

    final floatingButton =
        _buildFloatingButton(
      context,
      authSession,
    );

    if (navigationItems.length < 2) {
      return Scaffold(
        floatingActionButton:
            floatingButton,
        body: Column(
          children: [
            _buildMobileUserBar(
              context,
              authSession,
            ),
            Expanded(
              child: child,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        if (constraints.maxWidth >=
            900) {
          return Scaffold(
            floatingActionButton:
                floatingButton,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex:
                      selectedIndex,

                  onDestinationSelected:
                      (index) {
                    _navigate(
                      context,
                      navigationItems,
                      index,
                    );
                  },

                  labelType:
                      NavigationRailLabelType
                          .all,

                  leading:
                      const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    child: Icon(
                      Icons.local_library,
                      size: 32,
                    ),
                  ),

                  trailing:
                      _buildUserInfo(
                    context,
                    authSession,
                  ),

                  destinations:
                      navigationItems
                          .map(
                    (item) {
                      return NavigationRailDestination(
                        icon: Icon(
                          item.icon,
                        ),
                        selectedIcon:
                            Icon(
                          item.selectedIcon,
                        ),
                        label: Text(
                          item.label,
                        ),
                      );
                    },
                  ).toList(),
                ),

                const VerticalDivider(
                  width: 1,
                ),

                Expanded(
                  child: child,
                ),
              ],
            ),
          );
        }

        return Scaffold(
          floatingActionButton:
              floatingButton,

          body: Column(
            children: [
              _buildMobileUserBar(
                context,
                authSession,
              ),

              Expanded(
                child: child,
              ),
            ],
          ),

          bottomNavigationBar:
              NavigationBar(
            selectedIndex:
                selectedIndex,

            onDestinationSelected:
                (index) {
              _navigate(
                context,
                navigationItems,
                index,
              );
            },

            destinations:
                navigationItems
                    .map(
              (item) {
                return NavigationDestination(
                  icon: Icon(
                    item.icon,
                  ),
                  selectedIcon:
                      Icon(
                    item.selectedIcon,
                  ),
                  label:
                      item.label,
                );
              },
            ).toList(),
          ),
        );
      },
    );
  }
}

class _NavigationItem {
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavigationItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}