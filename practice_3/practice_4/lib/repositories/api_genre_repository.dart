import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import 'genre_repository.dart';

class ApiGenreRepository
    implements GenreRepository {
  final Dio _dio;

  ApiGenreRepository(this._dio);

  @override
  Future<PageResult<Genre>> find(
    GenreQuery query,
  ) {
    return guard(
      () async {
        final browserQuery =
            Uri.base.queryParameters;

        final response =
            await _dio.get(
          '/genres',
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
            <Genre>[];

        if (rawItems is List) {
          for (final item
              in rawItems) {
            if (item is Map) {
              items.add(
                Genre.fromJson(
                  Map<String, dynamic>
                      .from(item),
                ),
              );
            }
          }
        }

        return PageResult<Genre>(
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
  Future<Genre?> findById(
    int id,
  ) async {
    try {
      return await guard(
        () async {
          final response =
              await _dio.get(
            '/genres/$id',
          );

          return Genre.fromJson(
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
  Future<Genre> create(
    Genre genre,
  ) {
    return guard(
      () async {
        final response =
            await _dio.post(
          '/genres',
          data: _genreBody(
            genre,
          ),
        );

        return Genre.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  @override
  Future<Genre> update(
    Genre genre,
  ) {
    return guard(
      () async {
        final response =
            await _dio.put(
          '/genres/${genre.id}',
          data: _genreBody(
            genre,
          ),
        );

        return Genre.fromJson(
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
          '/genres/$id',
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
          '/genres/$id',
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
          '/genres/$id/restore',
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
          '/genres/bulk-delete',
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

  Map<String, dynamic> _genreBody(
    Genre genre,
  ) {
    return {
      'name':
          genre.name.trim(),
      'description':
          genre.description.trim(),
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