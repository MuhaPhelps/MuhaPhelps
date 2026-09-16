import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/auth_service.dart';
import 'core/auth_session.dart';
import 'core/lookup_cache.dart';
import 'core/session_timeout_watcher.dart';

import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_loan_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_reader_repository.dart';
import 'repositories/api_user_repository.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/loan_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'repositories/user_repository.dart';

import 'router.dart';

import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  // ----------------------------------------------
  // SHARED PREFERENCES
  // ----------------------------------------------

  final preferences =
      await SharedPreferences.getInstance();

  // ----------------------------------------------
  // AUTH SESSION
  // ----------------------------------------------

  final authSession =
      AuthSession();

  authSession.attachPreferences(
    preferences,
  );

  // ----------------------------------------------
  // AUTH SERVICE + DIO
  // ----------------------------------------------

  late final AuthService authService;

  final dio =
      buildDio(
    tokenProvider: () {
      return authSession.accessToken;
    },

    refreshToken: () {
      return authService.refresh();
    },

    onRefreshFailed: () {
      return authService.clearSession();
    },
  );

  authService =
      AuthService(
    dio,
    authSession,
  );

  // ----------------------------------------------
  // RESTORE SESSION
  // ----------------------------------------------

  await authService.restoreSession();

  // ----------------------------------------------
  // ROUTER
  // ----------------------------------------------

  final router =
      buildRouter(
    authSession,
  );

  // ----------------------------------------------
  // APPLICATION
  // ----------------------------------------------

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<
            AuthSession>.value(
          value: authSession,
        ),

        Provider<AuthService>.value(
          value: authService,
        ),

        Provider<Dio>.value(
          value: dio,
        ),

        ProxyProvider<
            Dio,
            BookRepository>(
          update: (
            _,
            dio,
            previous,
          ) {
            return previous ??
                ApiBookRepository(
                  dio,
                );
          },
        ),

        ProxyProvider<
            Dio,
            AuthorRepository>(
          update: (
            _,
            dio,
            previous,
          ) {
            return previous ??
                ApiAuthorRepository(
                  dio,
                );
          },
        ),

        ProxyProvider<
            Dio,
            GenreRepository>(
          update: (
            _,
            dio,
            previous,
          ) {
            return previous ??
                ApiGenreRepository(
                  dio,
                );
          },
        ),

        ProxyProvider2<
            Dio,
            BookRepository,
            PublisherRepository>(
          update: (
            _,
            dio,
            bookRepository,
            previous,
          ) {
            return previous ??
                ApiPublisherRepository(
                  dio,
                  bookRepository,
                );
          },
        ),

        ProxyProvider<
            Dio,
            ReaderRepository>(
          update: (
            _,
            dio,
            previous,
          ) {
            return previous ??
                ApiReaderRepository(
                  dio,
                );
          },
        ),

        ProxyProvider<
            Dio,
            LoanRepository>(
          update: (
            _,
            dio,
            previous,
          ) {
            return previous ??
                ApiLoanRepository(
                  dio,
                );
          },
        ),

        // ------------------------------------------
        // USERS
        // ------------------------------------------

        ProxyProvider<
            Dio,
            UserRepository>(
          update: (
            _,
            dio,
            previous,
          ) {
            return previous ??
                ApiUserRepository(
                  dio,
                );
          },
        ),

        ProxyProvider3<
            AuthorRepository,
            GenreRepository,
            PublisherRepository,
            LookupCache>(
          update: (
            _,
            authorRepository,
            genreRepository,
            publisherRepository,
            previous,
          ) {
            return previous ??
                LookupCache(
                  authorRepository,
                  genreRepository,
                  publisherRepository,
                );
          },
        ),

        ChangeNotifierProvider<
            BookListNotifier>(
          create: (
            context,
          ) =>
              BookListNotifier(
            context.read<
                BookRepository>(),
          )..load(),
        ),

        ChangeNotifierProvider<
            AuthorListNotifier>(
          create: (
            context,
          ) =>
              AuthorListNotifier(
            context.read<
                AuthorRepository>(),
          )..load(),
        ),

        ChangeNotifierProvider<
            GenreListNotifier>(
          create: (
            context,
          ) =>
              GenreListNotifier(
            context.read<
                GenreRepository>(),
          )..load(),
        ),

        ChangeNotifierProvider<
            PublisherListNotifier>(
          create: (
            context,
          ) =>
              PublisherListNotifier(
            context.read<
                PublisherRepository>(),
          )..load(),
        ),

        ChangeNotifierProvider<
            ReaderListNotifier>(
          create: (
            context,
          ) =>
              ReaderListNotifier(
            context.read<
                ReaderRepository>(),
          )..load(),
        ),
      ],

      child: LibraryApp(
        router: router,
      ),
    ),
  );
}

class LibraryApp
    extends StatelessWidget {
  final GoRouter router;

  const LibraryApp({
    super.key,
    required this.router,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp.router(
      title:
          'Библиотечная система',

      debugShowCheckedModeBanner:
          false,

      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              Colors.indigo,
        ),
        useMaterial3:
            true,
      ),

      routerConfig:
          router,

      builder: (
        context,
        child,
      ) {
        return SessionTimeoutWatcher(
          child:
              child ??
                  const SizedBox.shrink(),
        );
      },
    );
  }
}