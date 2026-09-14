import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/author_detail_screen.dart';
import 'screens/author_form_screen.dart';
import 'screens/authors_screen.dart';

import 'screens/book_detail_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/books_screen.dart';

import 'screens/genre_detail_screen.dart';
import 'screens/genre_form_screen.dart';
import 'screens/genres_screen.dart';

import 'screens/publisher_detail_screen.dart';
import 'screens/publisher_form_screen.dart';
import 'screens/publishers_screen.dart';

import 'screens/reader_detail_screen.dart';
import 'screens/reader_form_screen.dart';
import 'screens/readers_screen.dart';

import 'widgets/library_shell.dart';

final GoRouter appRouter =
    GoRouter(
  initialLocation: '/books',

  routes: [
    GoRoute(
      path: '/',
      redirect: (
        context,
        state,
      ) =>
          '/books',
    ),

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
        // BOOKS

        GoRoute(
          path: '/books',
          builder: (
            context,
            state,
          ) =>
              const BooksScreen(),
        ),

        GoRoute(
          path: '/books/new',
          builder: (
            context,
            state,
          ) =>
              const BookFormScreen(),
        ),

        GoRoute(
          path:
              '/books/:id/edit',
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

        // AUTHORS

        GoRoute(
          path: '/authors',
          builder: (
            context,
            state,
          ) =>
              const AuthorsScreen(),
        ),

        GoRoute(
          path: '/authors/new',
          builder: (
            context,
            state,
          ) =>
              const AuthorFormScreen(),
        ),

        GoRoute(
          path:
              '/authors/:id/edit',
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

        // GENRES

        GoRoute(
          path: '/genres',
          builder: (
            context,
            state,
          ) =>
              const GenresScreen(),
        ),

        GoRoute(
          path: '/genres/new',
          builder: (
            context,
            state,
          ) =>
              const GenreFormScreen(),
        ),

        GoRoute(
          path:
              '/genres/:id/edit',
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

        // PUBLISHERS

        GoRoute(
          path: '/publishers',
          builder: (
            context,
            state,
          ) =>
              const PublishersScreen(),
        ),

        GoRoute(
          path:
              '/publishers/new',
          builder: (
            context,
            state,
          ) =>
              const PublisherFormScreen(),
        ),

        GoRoute(
          path:
              '/publishers/:id/edit',
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

        // READERS

        GoRoute(
          path: '/readers',
          builder: (
            context,
            state,
          ) =>
              const ReadersScreen(),
        ),

        GoRoute(
          path: '/readers/new',
          builder: (
            context,
            state,
          ) =>
              const ReaderFormScreen(),
        ),

        GoRoute(
          path:
              '/readers/:id/edit',
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
      ],
    ),
  ],

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