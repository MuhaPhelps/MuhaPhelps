import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_models.dart';
import '../repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  static const _tokenKey = 'cae_token';
  static const _userKey = 'cae_user';

  final SharedPreferences preferences;
  final AuthRepository repository;

  String? _token;
  AppUser? _user;
  bool _busy = false;

  AuthController({required this.preferences, required this.repository});

  String? get token => _token;
  AppUser? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;
  bool get busy => _busy;

  Future<void> restore() async {
    final storedToken = preferences.getString(_tokenKey);
    final storedUser = preferences.getString(_userKey);

    if (storedToken == null || storedUser == null) {
      return;
    }

    try {
      final cached = AppUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(storedUser) as Map),
      );
      _token = storedToken;
      _user = cached;

      final refreshed = await repository.refresh(storedToken);
      await _apply(refreshed);
    } catch (_) {
      await logout();
    }
  }

  Future<void> login(String email, String password) async {
    _busy = true;
    notifyListeners();
    try {
      final result = await repository.login(email, password);
      await _apply(result);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await repository.register(name: name, email: email, password: password);
      final result = await repository.login(email, password);
      await _apply(result);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _apply(AuthResult result) async {
    _token = result.token;
    _user = result.user;
    await preferences.setString(_tokenKey, result.token);
    await preferences.setString(
      _userKey,
      jsonEncode({
        'id': result.user.id,
        'email': result.user.email,
        'name': result.user.name,
        'role': result.user.role.name,
      }),
    );
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await preferences.remove(_tokenKey);
    await preferences.remove(_userKey);
    notifyListeners();
  }
}
