import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import 'book_repository.dart';
import 'publisher_repository.dart';

class ApiPublisherRepository
    implements PublisherRepository {
  final Dio _dio;
  final BookRepository _bookRepository;

  ApiPublisherRepository(
    this._dio,
    this._bookRepository,
  );

  @override
  Future<PageResult<Publisher>> find(
    PublisherQuery query,
  ) {
    return guard(
      () async {
        final browserQuery =
            Uri.base.queryParameters;

        final response =
            await _dio.get(
          '/publishers',
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
            <Publisher>[];

        if (rawItems is List) {
          for (final item
              in rawItems) {
            if (item is Map) {
              items.add(
                Publisher.fromJson(
                  Map<String, dynamic>
                      .from(item),
                ),
              );
            }
          }
        }

        return PageResult<Publisher>(
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
  Future<Publisher?> findById(
    int id,
  ) async {
    try {
      return await guard(
        () async {
          final response =
              await _dio.get(
            '/publishers/$id',
          );

          return Publisher.fromJson(
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
  Future<Publisher> create(
    Publisher publisher,
  ) {
    return guard(
      () async {
        final response =
            await _dio.post(
          '/publishers',
          data: _publisherBody(
            publisher,
          ),
        );

        return Publisher.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  @override
  Future<Publisher> update(
    Publisher publisher,
  ) {
    return guard(
      () async {
        final response =
            await _dio.put(
          '/publishers/${publisher.id}',
          data: _publisherBody(
            publisher,
          ),
        );

        return Publisher.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  Future<int> _relatedBookCount(
    int publisherId,
  ) async {
    final result =
        await _bookRepository.find(
      BookQuery(
        publisherId: publisherId,
        includeDeleted: true,
        page: 1,
        size: 50,
      ),
    );

    return result.total;
  }

  Future<void> _assertCanDelete(
    int publisherId,
  ) async {
    final count =
        await _relatedBookCount(
      publisherId,
    );

    if (count > 0) {
      throw PublisherInUseException(
        count,
      );
    }
  }

  @override
  Future<void> softDelete(
    int id,
  ) async {
    await _assertCanDelete(id);

    try {
      await guard(
        () async {
          await _dio.delete(
            '/publishers/$id',
          );
        },
      );
    } on ConflictException {
      final count =
          await _relatedBookCount(id);

      if (count > 0) {
        throw PublisherInUseException(
          count,
        );
      }

      rethrow;
    }
  }

  @override
  Future<void> hardDelete(
    int id,
  ) async {
    await _assertCanDelete(id);

    try {
      await guard(
        () async {
          await _dio.delete(
            '/publishers/$id',
            queryParameters: {
              'hard': true,
            },
          );
        },
      );
    } on ConflictException {
      final count =
          await _relatedBookCount(id);

      if (count > 0) {
        throw PublisherInUseException(
          count,
        );
      }

      rethrow;
    }
  }

  @override
  Future<void> restore(
    int id,
  ) {
    return guard(
      () async {
        await _dio.post(
          '/publishers/$id/restore',
        );
      },
    );
  }

  @override
  Future<int> deleteMany(
    List<int> ids,
  ) async {
    final safeIds =
        <int>[];

    for (final id in ids) {
      final related =
          await _relatedBookCount(id);

      if (related == 0) {
        safeIds.add(id);
      }
    }

    if (safeIds.isEmpty) {
      return 0;
    }

    return guard(
      () async {
        final response =
            await _dio.post(
          '/publishers/bulk-delete',
          data: {
            'ids': safeIds,
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

  Map<String, dynamic> _publisherBody(
    Publisher publisher,
  ) {
    return {
      'name':
          publisher.name.trim(),
      'city':
          publisher.city.trim(),
      'foundedYear':
          publisher.foundedYear,
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