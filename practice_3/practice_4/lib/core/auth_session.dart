class AuthSession {
  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessTokenExpiresAt;

  String? get accessToken =>
      _accessToken;

  String? get refreshToken =>
      _refreshToken;

  DateTime? get accessTokenExpiresAt =>
      _accessTokenExpiresAt;

  bool get isAuthenticated {
    return _accessToken != null &&
        _accessToken!.isNotEmpty;
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
  }

  void clear() {
    _accessToken = null;
    _refreshToken = null;
    _accessTokenExpiresAt = null;
  }
}