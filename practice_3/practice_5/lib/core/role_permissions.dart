import 'auth_session.dart';

enum AppPermission {
  viewCatalog,

  viewOwnLoans,
  renewOwnLoans,

  manageBooks,
  manageDictionaries,
  manageReaders,
  manageLoans,

  manageUsers,
  manageRoles,

  hardDelete,
  restoreRecords,

  viewStatistics,
}

class RolePermissions {
  const RolePermissions._();

  static bool can(
    AppRole role,
    AppPermission permission,
  ) {
    switch (role) {
      case AppRole.reader:
        return _readerPermissions.contains(
          permission,
        );

      case AppRole.librarian:
        return _librarianPermissions.contains(
          permission,
        );

      case AppRole.admin:
        return _adminPermissions.contains(
          permission,
        );
    }
  }

  static const Set<AppPermission>
      _readerPermissions = {
    AppPermission.viewCatalog,
    AppPermission.viewOwnLoans,
    AppPermission.renewOwnLoans,
  };

  static const Set<AppPermission>
      _librarianPermissions = {
    AppPermission.viewCatalog,
    AppPermission.manageBooks,
    AppPermission.manageDictionaries,
    AppPermission.manageReaders,
    AppPermission.manageLoans,
  };

  static const Set<AppPermission>
      _adminPermissions = {
    AppPermission.viewCatalog,

    AppPermission.manageBooks,
    AppPermission.manageDictionaries,
    AppPermission.manageReaders,
    AppPermission.manageLoans,

    AppPermission.manageUsers,
    AppPermission.manageRoles,

    AppPermission.hardDelete,
    AppPermission.restoreRecords,

    AppPermission.viewStatistics,
  };
}

extension AppRolePermissions
    on AppRole {
  bool can(
    AppPermission permission,
  ) {
    return RolePermissions.can(
      this,
      permission,
    );
  }
}