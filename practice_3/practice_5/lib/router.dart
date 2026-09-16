import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/auth_session.dart';
import 'core/role_permissions.dart';

import 'screens/author_detail_screen.dart';
import 'screens/author_form_screen.dart';
import 'screens/authors_screen.dart';

import 'screens/book_detail_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/books_screen.dart';

import 'screens/forbidden_screen.dart';

import 'screens/genre_detail_screen.dart';
import 'screens/genre_form_screen.dart';
import 'screens/genres_screen.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

import 'screens/my_loans_screen.dart';

import 'screens/publisher_detail_screen.dart';
import 'screens/publisher_form_screen.dart';
import 'screens/publishers_screen.dart';

import 'screens/reader_detail_screen.dart';
import 'screens/reader_form_screen.dart';
import 'screens/readers_screen.dart';

import 'screens/users_screen.dart';

import 'widgets/library_shell.dart';

String? _requirePermission(
  AuthSession authSession,
  AppPermission permission,
) {
  final role =
      authSession.role;

  if (role == null) {
    return '/login';
  }

  if (!role.can(
    permission,
  )) {
    return '/forbidden';
  }

  return null;
}

GoRouter buildRouter(
  AuthSession authSession,
) {
  return GoRouter(
    initialLocation: '/',

    refreshListenable:
        authSession,

    redirect: (
      context,
      state,
    ) {
      final loggedIn =
          authSession
              .isAuthenticated;

      final target =
          state.matchedLocation;

      final isLogin =
          target == '/login';

      final isRegister =
          target == '/register';

      final isPublic =
          isLogin ||
          isRegister;

      if (!loggedIn &&
          !isPublic) {
        final from =
            Uri.encodeComponent(
          state.uri.toString(),
        );

        return '/login?from=$from';
      }

      if (loggedIn &&
          isPublic) {
        final from =
            state.uri
                .queryParameters[
                    'from'];

        if (from != null &&
            from.startsWith('/') &&
            !from.startsWith(
              '/login',
            ) &&
            !from.startsWith(
              '/register',
            )) {
          return from;
        }

        return '/books';
      }

      return null;
    },

    routes: [
      // ==========================================
      // PUBLIC
      // ==========================================

      GoRoute(
        path: '/login',
        builder: (
          context,
          state,
        ) {
          return LoginScreen(
            from:
                state.uri
                    .queryParameters[
                        'from'],
            registered:
                state.uri
                        .queryParameters[
                            'registered'] ==
                    '1',
            initialUsername:
                state.uri
                    .queryParameters[
                        'username'],
          );
        },
      ),

      GoRoute(
        path: '/register',
        builder: (
          context,
          state,
        ) {
          return RegisterScreen(
            from:
                state.uri
                    .queryParameters[
                        'from'],
          );
        },
      ),

      // ==========================================
      // ROOT
      // ==========================================

      GoRoute(
        path: '/',
        redirect: (
          context,
          state,
        ) =>
            '/books',
      ),

      // ==========================================
      // FORBIDDEN
      // ==========================================

      GoRoute(
        path: '/forbidden',
        builder: (
          context,
          state,
        ) =>
            const ForbiddenScreen(),
      ),

      // ==========================================
      // AUTHENTICATED AREA
      // ==========================================

      ShellRoute(
        builder: (
          context,
          state,
          child,
        ) {
          return LibraryShell(
            currentPath:
                state.uri.path,
            child: child,
          );
        },

        routes: [
          // ======================================
          // BOOKS
          // ======================================

          GoRoute(
            path: '/books',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .viewCatalog,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const BooksScreen(),
          ),

          GoRoute(
            path: '/books/new',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageBooks,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const BookFormScreen(),
          ),

          GoRoute(
            path: '/books/:id/edit',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageBooks,
              );
            },
            builder: (
              context,
              state,
            ) {
              final id =
                  int.tryParse(
                        state.pathParameters[
                                'id'] ??
                            '',
                      ) ??
                      -1;

              return BookFormScreen(
                id: id,
              );
            },
          ),

          GoRoute(
            path: '/books/:id',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .viewCatalog,
              );
            },
            builder: (
              context,
              state,
            ) {
              final id =
                  int.tryParse(
                        state.pathParameters[
                                'id'] ??
                            '',
                      ) ??
                      -1;

              return BookDetailScreen(
                bookId: id,
              );
            },
          ),

          // ======================================
          // MY LOANS
          // ======================================

          GoRoute(
            path: '/my-loans',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .viewOwnLoans,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const MyLoansScreen(),
          ),

          // ======================================
          // AUTHORS
          // ======================================

          GoRoute(
            path: '/authors',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .viewCatalog,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const AuthorsScreen(),
          ),

          GoRoute(
            path: '/authors/new',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageDictionaries,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const AuthorFormScreen(),
          ),

          GoRoute(
            path:
                '/authors/:id/edit',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageDictionaries,
              );
            },
            builder: (
              context,
              state,
            ) {
              final id =
                  int.tryParse(
                        state.pathParameters[
                                'id'] ??
                            '',
                      ) ??
                      -1;

              return AuthorFormScreen(
                id: id,
              );
            },
          ),

          GoRoute(
            path: '/authors/:id',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .viewCatalog,
              );
            },
            builder: (
              context,
              state,
            ) {
              final id =
                  int.tryParse(
                        state.pathParameters[
                                'id'] ??
                            '',
                      ) ??
                      -1;

              return AuthorDetailScreen(
                authorId: id,
              );
            },
          ),

          // ======================================
          // GENRES
          // ======================================

          GoRoute(
            path: '/genres',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .viewCatalog,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const GenresScreen(),
          ),

          GoRoute(
            path: '/genres/new',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageDictionaries,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const GenreFormScreen(),
          ),

          GoRoute(
            path:
                '/genres/:id/edit',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageDictionaries,
              );
            },
            builder: (
              context,
              state,
            ) {
              final id =
                  int.tryParse(
                        state.pathParameters[
                                'id'] ??
                            '',
                      ) ??
                      -1;

              return GenreFormScreen(
                id: id,
              );
            },
          ),

          GoRoute(
            path: '/genres/:id',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .viewCatalog,
              );
            },
            builder: (
              context,
              state,
            ) {
              final id =
                  int.tryParse(
                        state.pathParameters[
                                'id'] ??
                            '',
                      ) ??
                      -1;

              return GenreDetailScreen(
                genreId: id,
              );
            },
          ),

          // ======================================
          // PUBLISHERS
          // ======================================

          GoRoute(
            path: '/publishers',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .viewCatalog,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const PublishersScreen(),
          ),

          GoRoute(
            path: '/publishers/new',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageDictionaries,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const PublisherFormScreen(),
          ),

          GoRoute(
            path:
                '/publishers/:id/edit',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageDictionaries,
              );
            },
            builder: (
              context,
              state,
            ) {
              final id =
                  int.tryParse(
                        state.pathParameters[
                                'id'] ??
                            '',
                      ) ??
                      -1;

              return PublisherFormScreen(
                id: id,
              );
            },
          ),

          GoRoute(
            path:
                '/publishers/:id',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .viewCatalog,
              );
            },
            builder: (
              context,
              state,
            ) {
              final id =
                  int.tryParse(
                        state.pathParameters[
                                'id'] ??
                            '',
                      ) ??
                      -1;

              return PublisherDetailScreen(
                publisherId: id,
              );
            },
          ),

          // ======================================
          // READERS
          // ======================================

          GoRoute(
            path: '/readers',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageReaders,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const ReadersScreen(),
          ),

          GoRoute(
            path: '/readers/new',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageReaders,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const ReaderFormScreen(),
          ),

          GoRoute(
            path:
                '/readers/:id/edit',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageReaders,
              );
            },
            builder: (
              context,
              state,
            ) {
              final id =
                  int.tryParse(
                        state.pathParameters[
                                'id'] ??
                            '',
                      ) ??
                      -1;

              return ReaderFormScreen(
                id: id,
              );
            },
          ),

          GoRoute(
            path: '/readers/:id',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageReaders,
              );
            },
            builder: (
              context,
              state,
            ) {
              final id =
                  int.tryParse(
                        state.pathParameters[
                                'id'] ??
                            '',
                      ) ??
                      -1;

              return ReaderDetailScreen(
                readerId: id,
              );
            },
          ),

          // ======================================
          // ADMIN - USERS
          // ======================================

          GoRoute(
            path: '/admin/users',
            redirect: (
              context,
              state,
            ) {
              return _requirePermission(
                authSession,
                AppPermission
                    .manageUsers,
              );
            },
            builder: (
              context,
              state,
            ) =>
                const UsersScreen(),
          ),
        ],
      ),
    ],

    // ============================================
    // NOT FOUND
    // ============================================

    errorBuilder: (
      context,
      state,
    ) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Ошибка',
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
              ),

              const SizedBox(
                height: 16,
              ),

              const Text(
                'Страница не найдена',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                state.uri.toString(),
              ),

              const SizedBox(
                height: 16,
              ),

              FilledButton(
                onPressed: () {
                  context.go(
                    '/books',
                  );
                },
                child: const Text(
                  'Перейти к книгам',
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}