import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_web/core/api_exceptions.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/repositories/api_book_repository.dart';

void main() {
  group(
    'ApiBookRepository',
    () {
      test(
        'find разбирает страницу книг',
        () async {
          final dio = _fakeDio(
            (
              options,
              handler,
            ) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'items': [
                      {
                        'id': 1,
                        'title':
                            'Война и мир',
                        'isbn':
                            '978-5-17-118366-4',
                        'year': 1869,
                        'pages': 1300,
                        'publisher': {
                          'id': 1,
                          'name': 'АСТ',
                        },
                        'authors': [
                          {
                            'id': 1,
                            'fullName':
                                'Толстой Л. Н.',
                          },
                        ],
                        'genres': [
                          {
                            'id': 2,
                            'name': 'Роман',
                          },
                        ],
                        'copiesTotal': 4,
                        'copiesAvailable':
                            2,
                        'deletedAt': null,
                      },
                    ],
                    'page': 1,
                    'size': 10,
                    'total': 1,
                  },
                ),
              );
            },
          );

          final repository =
              ApiBookRepository(
            dio,
          );

          final result =
              await repository.find(
            const BookQuery(),
          );

          expect(
            result.items.length,
            1,
          );

          expect(
            result.items.first.title,
            'Война и мир',
          );

          expect(
            result.items.first.publisherId,
            1,
          );

          expect(
            result.items.first.authorIds,
            contains(1),
          );

          expect(
            result.items.first.genreIds,
            contains(2),
          );

          expect(
            result.total,
            1,
          );
        },
      );

      test(
        'find передаёт поиск, сортировку и пагинацию на сервер',
        () async {
          RequestOptions?
              capturedOptions;

          final dio = _fakeDio(
            (
              options,
              handler,
            ) {
              capturedOptions =
                  options;

              handler.resolve(
                Response(
                  requestOptions:
                      options,
                  statusCode: 200,
                  data: {
                    'items': [],
                    'page': 2,
                    'size': 25,
                    'total': 0,
                  },
                ),
              );
            },
          );

          final repository =
              ApiBookRepository(
            dio,
          );

          await repository.find(
            const BookQuery(
              search: 'война',
              genreId: 3,
              publisherId: 2,
              yearFrom: 1800,
              yearTo: 1900,
              sortField: 'year',
              sortAscending: false,
              page: 2,
              size: 25,
              includeDeleted: true,
            ),
          );

          expect(
            capturedOptions,
            isNotNull,
          );

          final query =
              capturedOptions!
                  .queryParameters;

          expect(
            query['search'],
            'война',
          );

          expect(
            query['genreId'],
            3,
          );

          expect(
            query['publisherId'],
            2,
          );

          expect(
            query['yearFrom'],
            1800,
          );

          expect(
            query['yearTo'],
            1900,
          );

          expect(
            query['sort'],
            'year,desc',
          );

          expect(
            query['page'],
            2,
          );

          expect(
            query['size'],
            25,
          );

          expect(
            query['includeDeleted'],
            true,
          );
        },
      );

      test(
        'create отправляет книгу и разбирает ответ',
        () async {
          RequestOptions?
              capturedOptions;

          final dio = _fakeDio(
            (
              options,
              handler,
            ) {
              capturedOptions =
                  options;

              handler.resolve(
                Response(
                  requestOptions:
                      options,
                  statusCode: 201,
                  data: {
                    'id': 15,
                    'title':
                        'Тестовая книга',
                    'isbn':
                        'TEST-123',
                    'year': 2026,
                    'pages': 300,
                    'publisher': {
                      'id': 1,
                      'name': 'АСТ',
                    },
                    'authors': [
                      {
                        'id': 1,
                        'fullName':
                            'Автор',
                      },
                    ],
                    'genres': [
                      {
                        'id': 2,
                        'name':
                            'Фантастика',
                      },
                    ],
                    'copiesTotal': 2,
                    'copiesAvailable':
                        2,
                    'deletedAt': null,
                  },
                ),
              );
            },
          );

          final repository =
              ApiBookRepository(
            dio,
          );

          final book = Book(
            id: 0,
            title:
                'Тестовая книга',
            isbn:
                'TEST-123',
            year: 2026,
            pages: 300,
            publisherId: 1,
            authorIds: const [
              1,
            ],
            genreIds: const [
              2,
            ],
            copiesTotal: 2,
            copiesAvailable: 2,
            deletedAt: null,
          );

          final created =
              await repository.create(
            book,
          );

          expect(
            capturedOptions!.method,
            'POST',
          );

          expect(
            capturedOptions!.path,
            '/books',
          );

          final body =
              Map<String, dynamic>.from(
            capturedOptions!.data
                as Map,
          );

          expect(
            body['title'],
            'Тестовая книга',
          );

          expect(
            body['isbn'],
            'TEST-123',
          );

          expect(
            body['copiesTotal'],
            2,
          );

          // copiesAvailable по контракту
          // при записи не отправляется.
          expect(
            body.containsKey(
              'copiesAvailable',
            ),
            false,
          );

          expect(
            created.id,
            15,
          );

          expect(
            created.title,
            'Тестовая книга',
          );
        },
      );

      test(
        'ответ 422 преобразуется в ValidationException',
        () async {
          final dio = _fakeDio(
            (
              options,
              handler,
            ) {
              handler.reject(
                DioException(
                  requestOptions:
                      options,
                  response: Response(
                    requestOptions:
                        options,
                    statusCode: 422,
                    data: {
                      'message':
                          'Ошибка валидации',
                      'errors': {
                        'isbn':
                            'Книга с таким ISBN уже существует',
                      },
                    },
                  ),
                  type:
                      DioExceptionType
                          .badResponse,
                ),
              );
            },
          );

          final repository =
              ApiBookRepository(
            dio,
          );

          final book = Book(
            id: 0,
            title:
                'Дубликат',
            isbn:
                'DUPLICATE',
            year: 2026,
            pages: 100,
            publisherId: 1,
            authorIds: const [
              1,
            ],
            genreIds: const [
              1,
            ],
            copiesTotal: 1,
            copiesAvailable: 1,
            deletedAt: null,
          );

          try {
            await repository.create(
              book,
            );

            fail(
              'Ожидался ValidationException',
            );
          } on ValidationException catch (
            error
          ) {
            expect(
              error.message,
              'Ошибка валидации',
            );

            expect(
              error.errors['isbn'],
              'Книга с таким ISBN уже существует',
            );
          }
        },
      );

      test(
        'недоступный сервер преобразуется в NetworkException',
        () async {
          final dio = _fakeDio(
            (
              options,
              handler,
            ) {
              handler.reject(
                DioException(
                  requestOptions:
                      options,
                  type:
                      DioExceptionType
                          .connectionError,
                  error: Exception(
                    'Connection refused',
                  ),
                ),
              );
            },
          );

          final repository =
              ApiBookRepository(
            dio,
          );

          expect(
            () => repository.find(
              const BookQuery(),
            ),
            throwsA(
              isA<
                  NetworkException>(),
            ),
          );
        },
      );

      test(
        'findById возвращает null при 404',
        () async {
          final dio = _fakeDio(
            (
              options,
              handler,
            ) {
              handler.reject(
                DioException(
                  requestOptions:
                      options,
                  response: Response(
                    requestOptions:
                        options,
                    statusCode: 404,
                    data: {
                      'message':
                          'Книга не найдена',
                    },
                  ),
                  type:
                      DioExceptionType
                          .badResponse,
                ),
              );
            },
          );

          final repository =
              ApiBookRepository(
            dio,
          );

          final result =
              await repository.findById(
            999,
          );

          expect(
            result,
            isNull,
          );
        },
      );
    },
  );
}

Dio _fakeDio(
  void Function(
    RequestOptions options,
    RequestInterceptorHandler handler,
  )
  onRequest,
) {
  final dio = Dio(
    BaseOptions(
      baseUrl:
          'http://localhost:8080/api',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: onRequest,
    ),
  );

  return dio;
}