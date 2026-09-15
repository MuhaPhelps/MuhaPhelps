import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

class ApiAuthorRepository
    implements AuthorRepository {
  final Dio _dio;

  ApiAuthorRepository(this._dio);

  @override
  Future<PageResult<Author>> find(
    AuthorQuery query,
  ) {
    return guard(
      () async {
        final browserQuery =
            Uri.base.queryParameters;

        final response =
            await _dio.get(
          '/authors',
          queryParameters: {
            if (query.search
                .trim()
                .isNotEmpty)
              'search':
                  query.search.trim(),

            'sort':
                '${query.sortField},'
                '${query.sortAscending ? 'asc' : 'desc'}',

            'page': query.page,
            'size': query.size,

            if (query.includeDeleted)
              'includeDeleted': true,

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
        );

        final data =
            Map<String, dynamic>.from(
          response.data as Map,
        );

        final rawItems =
            data['items'];

        final items =
            <Author>[];

        if (rawItems is List) {
          for (final item
              in rawItems) {
            if (item is Map) {
              items.add(
                Author.fromJson(
                  Map<String, dynamic>
                      .from(item),
                ),
              );
            }
          }
        }

        return PageResult<Author>(
          items: items,
          page: _toInt(
            data['page'],
            fallback: query.page,
          ),
          size: _toInt(
            data['size'],
            fallback: query.size,
          ),
          total: _toInt(
            data['total'],
          ),
        );
      },
    );
  }

  @override
  Future<Author?> findById(
    int id,
  ) async {
    try {
      return await guard(
        () async {
          final response =
              await _dio.get(
            '/authors/$id',
          );

          return Author.fromJson(
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
  Future<Author> create(
    Author author,
  ) {
    return guard(
      () async {
        final response =
            await _dio.post(
          '/authors',
          data: _authorBody(
            author,
          ),
        );

        return Author.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  @override
  Future<Author> update(
    Author author,
  ) {
    return guard(
      () async {
        final response =
            await _dio.put(
          '/authors/${author.id}',
          data: _authorBody(
            author,
          ),
        );

        return Author.fromJson(
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
          '/authors/$id',
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
          '/authors/$id',
          queryParameters: {
            'hard': true,
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
          '/authors/$id/restore',
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
          '/authors/bulk-delete',
          data: {
            'ids': ids,
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

  Map<String, dynamic> _authorBody(
    Author author,
  ) {
    return {
      'fullName':
          author.fullName.trim(),
      'birthYear':
          author.birthYear,
      'country':
          author.country.trim(),
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