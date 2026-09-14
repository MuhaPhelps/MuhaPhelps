import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/author_detail_screen.dart';
import 'screens/authors_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/books_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/books',

  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) {
        return '/books';
      },
    ),

    GoRoute(
      path: '/books',
      builder: (context, state) {
        return const BooksScreen();
      },
    ),

    GoRoute(
      path: '/books/:id',
      builder: (context, state) {
        final id = int.tryParse(
              state.pathParameters['id'] ?? '',
            ) ??
            -1;

        return BookDetailScreen(
          bookId: id,
        );
      },
    ),

    GoRoute(
      path: '/authors',
      builder: (context, state) {
        return const AuthorsScreen();
      },
    ),

    GoRoute(
      path: '/authors/:id',
      builder: (context, state) {
        final id = int.tryParse(
              state.pathParameters['id'] ?? '',
            ) ??
            -1;

        return AuthorDetailScreen(
          authorId: id,
        );
      },
    ),
  ],

  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ошибка',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Страница не найдена',
              style: TextStyle(
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                context.go('/books');
              },
              child: const Text(
                'К списку книг',
              ),
            ),
          ],
        ),
      ),
    );
  },
);