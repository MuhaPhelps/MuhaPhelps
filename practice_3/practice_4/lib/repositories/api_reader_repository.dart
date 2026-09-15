import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import 'reader_repository.dart';

class ApiReaderRepository
    implements ReaderRepository {
  final Dio _dio;

  ApiReaderRepository(this._dio);

  @override
  Future<PageResult<Reader>> find(
    ReaderQuery query,
  ) {
    return guard(
      () async {
        final browserQuery =
            Uri.base.queryParameters;

        final response =
            await _dio.get(
          '/readers',
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
            <Reader>[];

        if (rawItems is List) {
          for (final item
              in rawItems) {
            if (item is Map) {
              items.add(
                Reader.fromJson(
                  Map<String, dynamic>
                      .from(item),
                ),
              );
            }
          }
        }

        return PageResult<Reader>(
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
  Future<Reader?> findById(
    int id,
  ) async {
    try {
      return await guard(
        () async {
          final response =
              await _dio.get(
            '/readers/$id',
          );

          return Reader.fromJson(
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
  Future<Reader> create(
    Reader reader,
  ) async {
    try {
      return await guard(
        () async {
          final response =
              await _dio.post(
            '/readers',
            data: _readerBody(
              reader,
            ),
          );

          return Reader.fromJson(
            Map<String, dynamic>.from(
              response.data as Map,
            ),
          );
        },
      );
    } on ValidationException catch (error) {
      if (_isEmailError(error)) {
        throw ReaderEmailExistsException(
          reader.email,
        );
      }

      rethrow;
    } on ConflictException catch (error) {
      if (_isEmailConflict(error)) {
        throw ReaderEmailExistsException(
          reader.email,
        );
      }

      rethrow;
    }
  }

  @override
  Future<Reader> update(
    Reader reader,
  ) async {
    try {
      return await guard(
        () async {
          final response =
              await _dio.put(
            '/readers/${reader.id}',
            data: _readerBody(
              reader,
            ),
          );

          return Reader.fromJson(
            Map<String, dynamic>.from(
              response.data as Map,
            ),
          );
        },
      );
    } on ValidationException catch (error) {
      if (_isEmailError(error)) {
        throw ReaderEmailExistsException(
          reader.email,
        );
      }

      rethrow;
    } on ConflictException catch (error) {
      if (_isEmailConflict(error)) {
        throw ReaderEmailExistsException(
          reader.email,
        );
      }

      rethrow;
    }
  }

  @override
  Future<void> softDelete(
    int id,
  ) {
    return guard(
      () async {
        await _dio.delete(
          '/readers/$id',
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
          '/readers/$id',
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
          '/readers/$id/restore',
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
          '/readers/bulk-delete',
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

  Map<String, dynamic> _readerBody(
    Reader reader,
  ) {
    return {
      'fullName':
          reader.fullName.trim(),
      'email':
          reader.email.trim(),
      'phone':
          reader.phone.trim(),

      'card': {
        'number':
            reader.card.number.trim(),

        'issuedAt':
            reader.card.issuedAt
                ?.toIso8601String(),

        'expiresAt':
            reader.card.expiresAt
                ?.toIso8601String(),
      },
    };
  }

  bool _isEmailError(
    ValidationException error,
  ) {
    for (final entry
        in error.errors.entries) {
      final key =
          entry.key.toLowerCase();

      final value =
          entry.value.toLowerCase();

      if (key.contains('email') ||
          value.contains('email')) {
        return true;
      }
    }

    return false;
  }

  bool _isEmailConflict(
    ConflictException error,
  ) {
    final message =
        error.message.toLowerCase();

    return message.contains(
          'email',
        ) ||
        message.contains(
          'почт',
        );
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