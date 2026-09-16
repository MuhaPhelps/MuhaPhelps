import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppRole {
  reader,
  librarian,
  admin;

  static AppRole? fromString(
    String? value,
  ) {
    switch (value?.trim().toLowerCase()) {
      case 'reader':
        return AppRole.reader;

      case 'librarian':
        return AppRole.librarian;

      case 'admin':
        return AppRole.admin;

      default:
        return null;
    }
  }

  String get value {
    switch (this) {
      case AppRole.reader:
        return 'reader';

      case AppRole.librarian:
        return 'librarian';

      case AppRole.admin:
        return 'admin';
    }
  }

  String get title {
    switch (this) {
      case AppRole.reader:
        return 'Читатель';

      case AppRole.librarian:
        return 'Библиотекарь';

      case AppRole.admin:
        return 'Администратор';
    }
  }
}

class AppUser {
  final int? id;
  final String username;
  final String name;
  final AppRole role;

  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  factory AppUser.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawRole =
        json['role']?.toString();

    final role =
        AppRole.fromString(
      rawRole,
    );

    if (role == null) {
      throw StateError(
        'Неизвестная роль пользователя: $rawRole',
      );
    }

    final username =
        json['username']
                ?.toString()
                .trim() ??
            '';

    final name =
        _firstNotEmpty([
      json['name']?.toString(),
      json['fullName']?.toString(),
      json['displayName']?.toString(),
      username,
    ]);

    return AppUser(
      id: _toNullableInt(
        json['id'],
      ),
      username: username,
      name: name,
      role: role,
    );
  }

  static String _firstNotEmpty(
    List<String?> values,
  ) {
    for (final value in values) {
      final text =
          value?.trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return 'Пользователь';
  }

  static int? _toNullableInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }
}

class AuthSession
    extends ChangeNotifier {
  static const String _accessKey =
      'auth_access_token';

  static const String _refreshKey =
      'auth_refresh_token';

  static const String _expiresAtKey =
      'auth_access_expires_at';

  static const String _sessionStartedAtKey =
      'auth_session_started_at';

  // Эта роль используется ТОЛЬКО интерфейсом.
  // Сервер ей не доверяет.
  static const String _uiRoleKey =
      'auth_ui_role';

  SharedPreferences? _preferences;

  String? _accessToken;
  String? _refreshToken;

  DateTime? _accessTokenExpiresAt;
  DateTime? _sessionStartedAt;

  AppUser? _user;

  // Локальная роль для отображения интерфейса.
  //
  // Намеренно хранится на клиенте,
  // чтобы в практической работе показать:
  // клиентские проверки можно подделать,
  // но сервер всё равно защищает данные.
  AppRole? _uiRole;

  AuthSession();

  String? get accessToken =>
      _accessToken;

  String? get refreshToken =>
      _refreshToken;

  DateTime? get accessTokenExpiresAt =>
      _accessTokenExpiresAt;

  DateTime? get sessionStartedAt =>
      _sessionStartedAt;

  AppUser? get user =>
      _user;

  // Для маршрутов и кнопок используем
  // локальную UI-роль.
  AppRole? get role =>
      _uiRole ?? _user?.role;

  // Настоящая роль, пришедшая от сервера.
  AppRole? get serverRole =>
      _user?.role;

  String get userDisplayName {
    return _user?.name ??
        _user?.username ??
        '';
  }

  bool get hasTokens {
    return _accessToken != null &&
        _accessToken!.isNotEmpty;
  }

  bool get isAuthenticated {
    return hasTokens &&
        _user != null;
  }

  bool get isAccessTokenExpired {
    final expiresAt =
        _accessTokenExpiresAt;

    if (expiresAt == null) {
      return true;
    }

    return DateTime.now().isAfter(
      expiresAt,
    );
  }

  bool hasRole(
    AppRole role,
  ) {
    return this.role == role;
  }

  bool hasAnyRole(
    Iterable<AppRole> roles,
  ) {
    final currentRole =
        role;

    if (currentRole == null) {
      return false;
    }

    return roles.contains(
      currentRole,
    );
  }

  void attachPreferences(
    SharedPreferences preferences,
  ) {
    _preferences =
        preferences;
  }

  Future<void> restoreTokens() async {
    final preferences =
        _preferences;

    if (preferences == null) {
      return;
    }

    final accessToken =
        preferences.getString(
      _accessKey,
    );

    final refreshToken =
        preferences.getString(
      _refreshKey,
    );

    final expiresAtMillis =
        preferences.getInt(
      _expiresAtKey,
    );

    final sessionStartedAtMillis =
        preferences.getInt(
      _sessionStartedAtKey,
    );

    final savedUiRole =
        preferences.getString(
      _uiRoleKey,
    );

    _accessToken =
        accessToken;

    _refreshToken =
        refreshToken;

    _uiRole =
        AppRole.fromString(
      savedUiRole,
    );

    if (expiresAtMillis != null) {
      _accessTokenExpiresAt =
          DateTime
              .fromMillisecondsSinceEpoch(
        expiresAtMillis,
      );
    } else {
      _accessTokenExpiresAt =
          null;
    }

    if (sessionStartedAtMillis !=
        null) {
      _sessionStartedAt =
          DateTime
              .fromMillisecondsSinceEpoch(
        sessionStartedAtMillis,
      );
    } else if (accessToken != null &&
        accessToken.isNotEmpty) {
      _sessionStartedAt =
          DateTime.now();

      await preferences.setInt(
        _sessionStartedAtKey,
        _sessionStartedAt!
            .millisecondsSinceEpoch,
      );
    } else {
      _sessionStartedAt =
          null;
    }

    notifyListeners();
  }

  void updateTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) {
    _accessToken =
        accessToken;

    _refreshToken =
        refreshToken;

    _accessTokenExpiresAt =
        DateTime.now().add(
      Duration(
        seconds: expiresIn,
      ),
    );

    // При refresh время начала всей
    // сессии не меняется.
    _sessionStartedAt ??=
        DateTime.now();

    notifyListeners();
  }

  void setUser(
    AppUser user,
  ) {
    _user =
        user;

    // Если локальной UI-роли ещё нет,
    // берём роль, которую вернул сервер.
    //
    // Если значение уже было загружено
    // из localStorage, специально его
    // не перезаписываем. Это позволит
    // продемонстрировать подмену UI.
    if (_uiRole == null) {
      _uiRole =
          user.role;

      final preferences =
          _preferences;

      if (preferences != null) {
        preferences.setString(
          _uiRoleKey,
          user.role.value,
        );
      }
    }

    notifyListeners();
  }

  void clearUser() {
    _user =
        null;

    notifyListeners();
  }

  Future<void> persistTokens() async {
    final preferences =
        _preferences;

    if (preferences == null) {
      return;
    }

    final accessToken =
        _accessToken;

    final refreshToken =
        _refreshToken;

    final expiresAt =
        _accessTokenExpiresAt;

    final sessionStartedAt =
        _sessionStartedAt;

    final uiRole =
        _uiRole;

    if (accessToken == null ||
        refreshToken == null) {
      return;
    }

    await preferences.setString(
      _accessKey,
      accessToken,
    );

    await preferences.setString(
      _refreshKey,
      refreshToken,
    );

    if (expiresAt != null) {
      await preferences.setInt(
        _expiresAtKey,
        expiresAt
            .millisecondsSinceEpoch,
      );
    }

    if (sessionStartedAt != null) {
      await preferences.setInt(
        _sessionStartedAtKey,
        sessionStartedAt
            .millisecondsSinceEpoch,
      );
    }

    if (uiRole != null) {
      await preferences.setString(
        _uiRoleKey,
        uiRole.value,
      );
    }
  }

  Future<void>
      clearPersistentData() async {
    final preferences =
        _preferences;

    if (preferences == null) {
      return;
    }

    await preferences.remove(
      _accessKey,
    );

    await preferences.remove(
      _refreshKey,
    );

    await preferences.remove(
      _expiresAtKey,
    );

    await preferences.remove(
      _sessionStartedAtKey,
    );

    await preferences.remove(
      _uiRoleKey,
    );
  }

  void clear() {
    _accessToken =
        null;

    _refreshToken =
        null;

    _accessTokenExpiresAt =
        null;

    _sessionStartedAt =
        null;

    _user =
        null;

    _uiRole =
        null;

    notifyListeners();
  }
}