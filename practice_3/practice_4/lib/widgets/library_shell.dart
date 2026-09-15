import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LibraryShell
    extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const LibraryShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  static const List<String> _routes = [
    '/books',
    '/authors',
    '/genres',
    '/publishers',
    '/readers',
  ];

  bool get _isFormRoute {
    if (currentPath.endsWith(
      '/new',
    )) {
      return true;
    }

    return RegExp(
      r'^/(books|authors|genres|publishers|readers)/\d+/edit$',
    ).hasMatch(
      currentPath,
    );
  }

  int get _selectedIndex {
    if (currentPath.startsWith(
      '/authors',
    )) {
      return 1;
    }

    if (currentPath.startsWith(
      '/genres',
    )) {
      return 2;
    }

    if (currentPath.startsWith(
      '/publishers',
    )) {
      return 3;
    }

    if (currentPath.startsWith(
      '/readers',
    )) {
      return 4;
    }

    return 0;
  }

  void _navigate(
    BuildContext context,
    int index,
  ) {
    final target =
        _routes[index];

    if (currentPath == target) {
      return;
    }

    context.go(target);
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
      label: Text(label),
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
  ) {
    if (currentPath == '/books') {
      return _createButton(
        context: context,
        path: '/books/new',
        label: 'Добавить книгу',
      );
    }

    if (currentPath == '/authors') {
      return _createButton(
        context: context,
        path: '/authors/new',
        label: 'Добавить автора',
      );
    }

    if (currentPath == '/genres') {
      return _createButton(
        context: context,
        path: '/genres/new',
        label: 'Добавить жанр',
      );
    }

    if (currentPath ==
        '/publishers') {
      return _createButton(
        context: context,
        path: '/publishers/new',
        label:
            'Добавить издательство',
      );
    }

    if (currentPath == '/readers') {
      return _createButton(
        context: context,
        path: '/readers/new',
        label:
            'Добавить читателя',
      );
    }

    final bookMatch =
        RegExp(
      r'^/books/(\d+)$',
    ).firstMatch(
      currentPath,
    );

    if (bookMatch != null) {
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
      return _editButton(
        context: context,
        path:
            '/readers/${readerMatch.group(1)}/edit',
      );
    }

    return null;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    // На экранах создания и редактирования
    // убираем общую навигацию.
    //
    // Выход с формы происходит только через
    // её собственный PopScope / кнопку Назад.
    if (_isFormRoute) {
      return child;
    }

    final floatingButton =
        _buildFloatingButton(
      context,
    );

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
                      _selectedIndex,

                  onDestinationSelected:
                      (index) {
                    _navigate(
                      context,
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

                  destinations:
                      const [
                    NavigationRailDestination(
                      icon: Icon(
                        Icons
                            .menu_book_outlined,
                      ),
                      selectedIcon:
                          Icon(
                        Icons.menu_book,
                      ),
                      label: Text(
                        'Книги',
                      ),
                    ),

                    NavigationRailDestination(
                      icon: Icon(
                        Icons
                            .people_outline,
                      ),
                      selectedIcon:
                          Icon(
                        Icons.people,
                      ),
                      label: Text(
                        'Авторы',
                      ),
                    ),

                    NavigationRailDestination(
                      icon: Icon(
                        Icons
                            .category_outlined,
                      ),
                      selectedIcon:
                          Icon(
                        Icons.category,
                      ),
                      label: Text(
                        'Жанры',
                      ),
                    ),

                    NavigationRailDestination(
                      icon: Icon(
                        Icons
                            .business_outlined,
                      ),
                      selectedIcon:
                          Icon(
                        Icons.business,
                      ),
                      label: Text(
                        'Издательства',
                      ),
                    ),

                    NavigationRailDestination(
                      icon: Icon(
                        Icons
                            .badge_outlined,
                      ),
                      selectedIcon:
                          Icon(
                        Icons.badge,
                      ),
                      label: Text(
                        'Читатели',
                      ),
                    ),
                  ],
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

          body: child,

          bottomNavigationBar:
              NavigationBar(
            selectedIndex:
                _selectedIndex,

            onDestinationSelected:
                (index) {
              _navigate(
                context,
                index,
              );
            },

            destinations:
                const [
              NavigationDestination(
                icon: Icon(
                  Icons
                      .menu_book_outlined,
                ),
                selectedIcon:
                    Icon(
                  Icons.menu_book,
                ),
                label: 'Книги',
              ),

              NavigationDestination(
                icon: Icon(
                  Icons
                      .people_outline,
                ),
                selectedIcon:
                    Icon(
                  Icons.people,
                ),
                label: 'Авторы',
              ),

              NavigationDestination(
                icon: Icon(
                  Icons
                      .category_outlined,
                ),
                selectedIcon:
                    Icon(
                  Icons.category,
                ),
                label: 'Жанры',
              ),

              NavigationDestination(
                icon: Icon(
                  Icons
                      .business_outlined,
                ),
                selectedIcon:
                    Icon(
                  Icons.business,
                ),
                label:
                    'Издательства',
              ),

              NavigationDestination(
                icon: Icon(
                  Icons.badge_outlined,
                ),
                selectedIcon:
                    Icon(
                  Icons.badge,
                ),
                label: 'Читатели',
              ),
            ],
          ),
        );
      },
    );
  }
}