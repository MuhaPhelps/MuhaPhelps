import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/auth_session.dart';
import 'package:library_web/core/role_permissions.dart';

void main() {
  group(
    'RolePermissions',
    () {
      test(
        'reader может смотреть каталог',
        () {
          expect(
            AppRole.reader.can(
              AppPermission.viewCatalog,
            ),
            isTrue,
          );
        },
      );

      test(
        'reader может смотреть свои выдачи',
        () {
          expect(
            AppRole.reader.can(
              AppPermission.viewOwnLoans,
            ),
            isTrue,
          );
        },
      );

      test(
        'reader не может управлять книгами',
        () {
          expect(
            AppRole.reader.can(
              AppPermission.manageBooks,
            ),
            isFalse,
          );
        },
      );

      test(
        'reader не может управлять пользователями',
        () {
          expect(
            AppRole.reader.can(
              AppPermission.manageUsers,
            ),
            isFalse,
          );
        },
      );

      test(
        'librarian может управлять книгами',
        () {
          expect(
            AppRole.librarian.can(
              AppPermission.manageBooks,
            ),
            isTrue,
          );
        },
      );

      test(
        'librarian может работать с читателями',
        () {
          expect(
            AppRole.librarian.can(
              AppPermission.manageReaders,
            ),
            isTrue,
          );
        },
      );

      test(
        'librarian не может управлять пользователями',
        () {
          expect(
            AppRole.librarian.can(
              AppPermission.manageUsers,
            ),
            isFalse,
          );
        },
      );

      test(
        'admin может управлять пользователями',
        () {
          expect(
            AppRole.admin.can(
              AppPermission.manageUsers,
            ),
            isTrue,
          );
        },
      );

      test(
        'admin может выполнять физическое удаление',
        () {
          expect(
            AppRole.admin.can(
              AppPermission.hardDelete,
            ),
            isTrue,
          );
        },
      );

      test(
        'admin может просматривать статистику',
        () {
          expect(
            AppRole.admin.can(
              AppPermission.viewStatistics,
            ),
            isTrue,
          );
        },
      );
    },
  );
}