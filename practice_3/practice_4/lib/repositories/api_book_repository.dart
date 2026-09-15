import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class ApiBookRepository
    implements
        BookRepository,
        CancellableBookRepository {
  final Dio _dio;

  CancelToken? _listCancelToken;

  ApiBookRepository(
    this._dio,
  );

  @override
  Future<PageResult<Book>> find(
    BookQuery query,
  ) {
    return guard(
      () => _requestFind(
        query,
      ),
    );
  }

  @override
  Future<PageResult<Book>> findCancellable(
    BookQuery query,
  ) async {
    _listCancelToken?.cancel(
      'Отменён из-за нового запроса поиска',
    );

    final cancelToken =
        CancelToken();

    _listCancelToken =
        cancelToken;

    try {
      return await _requestFind(
        query,
        cancelToken:
            cancelToken,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(
        error,
      )) {
        throw const BookSearchCancelledException();
      }

      throw mapDioError(
        error,
      );
    } finally {
      if (identical(
        _listCancelToken,
        cancelToken,
      )) {
        _listCancelToken =
            null;
      }
    }
  }

  Future<PageResult<Book>> _requestFind(
    BookQuery query, {
    CancelToken? cancelToken,
  }) async {
    final browserQuery =
        Uri.base.queryParameters;

    final response =
        await _dio.get(
      '/books',
      queryParameters: {
        if (query.search
            .trim()
            .isNotEmpty)
          'search':
              query.search.trim(),

        if (query.genreId != null)
          'genreId':
              query.genreId,

        if (query.publisherId != null)
          'publisherId':
              query.publisherId,

        if (query.yearFrom != null)
          'yearFrom':
              query.yearFrom,

        if (query.yearTo != null)
          'yearTo':
              query.yearTo,

        'sort':
            '${query.sortField},'
            '${query.sortAscending ? 'asc' : 'desc'}',

        'page':
            query.page,

        'size':
            query.size,

        if (query.includeDeleted)
          'includeDeleted':
              true,

        if (browserQuery[
                '__delay'] !=
            null)
          '__delay':
              browserQuery[
                  '__delay'],

        if (browserQuery[
                '__fail'] !=
            null)
          '__fail':
              browserQuery[
                  '__fail'],
      },
      cancelToken:
          cancelToken,
    );

    final data =
        Map<String, dynamic>.from(
      response.data as Map,
    );

    final rawItems =
        data['items'];

    final items =
        <Book>[];

    if (rawItems is List) {
      for (final item
          in rawItems) {
        if (item is Map) {
          items.add(
            Book.fromJson(
              Map<String, dynamic>
                  .from(
                item,
              ),
            ),
          );
        }
      }
    }

    return PageResult<Book>(
      items:
          items,
      page:
          _toInt(
        data['page'],
        fallback:
            query.page,
      ),
      size:
          _toInt(
        data['size'],
        fallback:
            query.size,
      ),
      total:
          _toInt(
        data['total'],
      ),
    );
  }

  @override
  Future<Book?> findById(
    int id,
  ) async {
    try {
      return await guard(
        () async {
          final response =
              await _dio.get(
            '/books/$id',
          );

          return Book.fromJson(
            Map<String, dynamic>.from(
              response.data as Map,
            ),
          );
        },
      );
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Book> create(
    Book book,
  ) {
    return guard(
      () async {
        final response =
            await _dio.post(
          '/books',
          data:
              _bookBody(
            book,
          ),
        );

        return Book.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  @override
  Future<Book> update(
    Book book,
  ) {
    return guard(
      () async {
        final response =
            await _dio.put(
          '/books/${book.id}',
          data:
              _bookBody(
            book,
          ),
        );

        return Book.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  @override
  Future<void> softDelete(
    int id,
  ) {
    return guard(
      () async {
        await _dio.delete(
          '/books/$id',
        );
      },
    );
  }

  @override
  Future<void> hardDelete(
    int id,
  ) {
    return guard(
      () async {
        await _dio.delete(
          '/books/$id',
          queryParameters: {
            'hard':
                true,
          },
        );
      },
    );
  }

  @override
  Future<void> restore(
    int id,
  ) {
    return guard(
      () async {
        await _dio.post(
          '/books/$id/restore',
        );
      },
    );
  }

  @override
  Future<int> deleteMany(
    List<int> ids,
  ) {
    return guard(
      () async {
        final response =
            await _dio.post(
          '/books/bulk-delete',
          data: {
            'ids':
                ids,
          },
        );

        final data =
            Map<String, dynamic>.from(
          response.data as Map,
        );

        return _toInt(
          data['deleted'],
        );
      },
    );
  }

  Map<String, dynamic> _bookBody(
    Book book,
  ) {
    return {
      'title':
          book.title.trim(),
      'isbn':
          book.isbn.trim(),
      'year':
          book.year,
      'pages':
          book.pages,
      'publisherId':
          book.publisherId,
      'authorIds': [
        ...book.authorIds,
      ],
      'genreIds': [
        ...book.genreIds,
      ],
      'copiesTotal':
          book.copiesTotal,
    };
  }

  int _toInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }
}