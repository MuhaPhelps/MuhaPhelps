import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/persistent_author_repository.dart';
import 'repositories/persistent_book_repository.dart';
import 'repositories/persistent_genre_repository.dart';
import 'repositories/persistent_publisher_repository.dart';
import 'repositories/persistent_reader_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';

import 'router.dart';

import 'services/storage_migration_service.dart';

import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  final prefs =
      await SharedPreferences.getInstance();

  final migrationService =
      StorageMigrationService(
    prefs,
  );

  final migrationResult =
      await migrationService.migrate();

  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>(
          create: (_) =>
              PersistentBookRepository(
            prefs,
          ),
        ),

        Provider<AuthorRepository>(
          create: (_) =>
              PersistentAuthorRepository(
            prefs,
          ),
        ),

        Provider<GenreRepository>(
          create: (_) =>
              PersistentGenreRepository(
            prefs,
          ),
        ),

        Provider<PublisherRepository>(
          create: (context) =>
              PersistentPublisherRepository(
            prefs,
            context.read<
                BookRepository>(),
          ),
        ),

        Provider<ReaderRepository>(
          create: (_) =>
              PersistentReaderRepository(
            prefs,
          ),
        ),

        ChangeNotifierProvider<
            BookListNotifier>(
          create: (context) =>
              BookListNotifier(
            context.read<
                BookRepository>(),
          )..load(),
        ),

        ChangeNotifierProvider<
            AuthorListNotifier>(
          create: (context) =>
              AuthorListNotifier(
            context.read<
                AuthorRepository>(),
          )..load(),
        ),

        ChangeNotifierProvider<
            GenreListNotifier>(
          create: (context) =>
              GenreListNotifier(
            context.read<
                GenreRepository>(),
          )..load(),
        ),

        ChangeNotifierProvider<
            PublisherListNotifier>(
          create: (context) =>
              PublisherListNotifier(
            context.read<
                PublisherRepository>(),
          )..load(),
        ),

        ChangeNotifierProvider<
            ReaderListNotifier>(
          create: (context) =>
              ReaderListNotifier(
            context.read<
                ReaderRepository>(),
          )..load(),
        ),
      ],

      child: LibraryApp(
        startupMessage:
            migrationResult.message,
      ),
    ),
  );
}

class LibraryApp
    extends StatefulWidget {
  final String? startupMessage;

  const LibraryApp({
    super.key,
    this.startupMessage,
  });

  @override
  State<LibraryApp> createState() =>
      _LibraryAppState();
}

class _LibraryAppState
    extends State<LibraryApp> {
  final GlobalKey<ScaffoldMessengerState>
      _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    if (widget.startupMessage != null) {
      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          _messengerKey.currentState
              ?.showSnackBar(
            SnackBar(
              content: Text(
                widget.startupMessage!,
              ),
              duration:
                  const Duration(
                seconds: 6,
              ),
              behavior:
                  SnackBarBehavior.floating,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp.router(
      title:
          'Библиотечная система',

      debugShowCheckedModeBanner:
          false,

      scaffoldMessengerKey:
          _messengerKey,

      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              Colors.indigo,
        ),
        useMaterial3: true,
      ),

      routerConfig:
          appRouter,
    );
  }
}