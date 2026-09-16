import '../models/author.dart';
import '../models/author_query.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../repositories/author_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';

class LookupCache {
  final AuthorRepository _authorRepository;
  final GenreRepository _genreRepository;
  final PublisherRepository _publisherRepository;

  LookupCache(
    this._authorRepository,
    this._genreRepository,
    this._publisherRepository,
  );

  Future<List<Author>>? _authorsFuture;
  Future<List<Genre>>? _genresFuture;
  Future<List<Publisher>>? _publishersFuture;

  Future<List<Author>> getAuthors() {
    _authorsFuture ??= _loadAuthors();

    return _authorsFuture!;
  }

  Future<List<Genre>> getGenres() {
    _genresFuture ??= _loadGenres();

    return _genresFuture!;
  }

  Future<List<Publisher>> getPublishers() {
    _publishersFuture ??=
        _loadPublishers();

    return _publishersFuture!;
  }

  Future<List<Author>> _loadAuthors() async {
    final result =
        await _authorRepository.find(
      const AuthorQuery(
        page: 1,
        size: 100,
      ),
    );

    final items = [
      ...result.items,
    ];

    items.sort(
      (a, b) =>
          a.fullName.compareTo(
        b.fullName,
      ),
    );

    return items;
  }

  Future<List<Genre>> _loadGenres() async {
    final result =
        await _genreRepository.find(
      const GenreQuery(
        page: 1,
        size: 100,
      ),
    );

    final items = [
      ...result.items,
    ];

    items.sort(
      (a, b) =>
          a.name.compareTo(
        b.name,
      ),
    );

    return items;
  }

  Future<List<Publisher>>
      _loadPublishers() async {
    final result =
        await _publisherRepository.find(
      const PublisherQuery(
        page: 1,
        size: 100,
      ),
    );

    final items = [
      ...result.items,
    ];

    items.sort(
      (a, b) =>
          a.name.compareTo(
        b.name,
      ),
    );

    return items;
  }

  void invalidateAuthors() {
    _authorsFuture = null;
  }

  void invalidateGenres() {
    _genresFuture = null;
  }

  void invalidatePublishers() {
    _publishersFuture = null;
  }

  void invalidateAll() {
    _authorsFuture = null;
    _genresFuture = null;
    _publishersFuture = null;
  }
}