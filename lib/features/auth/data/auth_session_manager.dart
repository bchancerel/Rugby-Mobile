import 'dart:convert';

import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_models.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_repository.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_token_store.dart';

typedef AuthenticatedRequest<T> = Future<T> Function(String accessToken);

class AuthSessionManager {
  AuthSessionManager({
    AuthRepository? repository,
    AuthTokenStore? tokenStore,
  })  : _repository = repository ?? AuthRepository(),
        _tokenStore = tokenStore ?? const SecureAuthTokenStore();

  static final instance = AuthSessionManager();

  final AuthRepository _repository;
  final AuthTokenStore _tokenStore;

  AuthUser? _user;
  bool _initialized = false;
  Future<AuthTokens?>? _refreshRequest;

  AuthUser? get user => _user;
  bool get initialized => _initialized;
  bool get isAuthenticated => _user != null;

  Future<bool> hasStoredSession() async {
    final tokens = await _tokenStore.read();
    final hasCompleteTokens = tokens != null && tokens.isComplete;

    if (!hasCompleteTokens) {
      _user = null;
      _initialized = true;
    }

    return hasCompleteTokens;
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final session = await _repository.login(
      email: email,
      password: password,
    );

    await _saveSession(session);
    return session.user;
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    String? username,
  }) async {
    final session = await _repository.register(
      email: email,
      password: password,
      username: username,
    );

    await _saveSession(session);
    return session.user;
  }

  Future<AuthUser?> restoreSession() async {
    final tokens = await _tokenStore.read();
    if (tokens == null || !tokens.isComplete) {
      _user = null;
      _initialized = true;
      return null;
    }

    if (_isTokenExpired(tokens.refreshToken)) {
      await clearSession();
      _initialized = true;
      return null;
    }

    if (_isTokenExpired(tokens.accessToken)) {
      return refreshSession(refreshToken: tokens.refreshToken);
    }

    try {
      _user = await _repository.fetchMe(accessToken: tokens.accessToken);
      return _user;
    } on AuthApiException catch (error) {
      if (error.statusCode != 401) {
        _user = _userFromToken(tokens.accessToken);
        rethrow;
      }

      return refreshSession(refreshToken: tokens.refreshToken);
    } finally {
      _initialized = true;
    }
  }

  Future<AuthUser?> refreshSession({String? refreshToken}) async {
    final tokensBeforeRefresh = await _tokenStore.read();
    try {
      final nextTokens = await _refreshTokens(refreshToken: refreshToken);
      if (nextTokens == null) {
        return null;
      }

      _user = await _repository.fetchMe(accessToken: nextTokens.accessToken);
      return _user;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await clearSession();
        return null;
      }

      final tokens = await _tokenStore.read();
      final fallbackToken = tokens?.accessToken ?? tokensBeforeRefresh?.accessToken;
      if (fallbackToken != null && !_isTokenExpired(fallbackToken)) {
        _user = _userFromToken(fallbackToken);
      } else {
        _user = null;
      }

      rethrow;
    } finally {
      _initialized = true;
    }
  }

  Future<T> runAuthenticated<T>(AuthenticatedRequest<T> request) async {
    final tokens = await _requireTokens();
    final accessToken = _isTokenExpired(tokens.accessToken)
        ? (await _refreshTokens(refreshToken: tokens.refreshToken))?.accessToken
        : tokens.accessToken;

    if (accessToken == null) {
      throw const AuthApiException(
        message: 'Session expiree. Reconnecte-toi pour continuer.',
        statusCode: 401,
      );
    }

    try {
      return await request(accessToken);
    } on AuthApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }
    }

    final nextTokens = await _refreshTokens(refreshToken: tokens.refreshToken);
    if (nextTokens == null) {
      throw const AuthApiException(
        message: 'Session expiree. Reconnecte-toi pour continuer.',
        statusCode: 401,
      );
    }

    try {
      return await request(nextTokens.accessToken);
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await clearSession();
      }

      rethrow;
    }
  }

  Future<void> logout() async {
    final tokens = await _tokenStore.read();

    try {
      await _repository.logout(
        accessToken: tokens?.accessToken,
        refreshToken: tokens?.refreshToken,
      );
    } finally {
      await clearSession();
      _initialized = true;
    }
  }

  Future<AuthUser> updateMe({
    String? username,
    String? currentPassword,
    String? password,
  }) async {
    _user = await runAuthenticated(
      (accessToken) => _repository.updateMe(
        accessToken: accessToken,
        username: username,
        currentPassword: currentPassword,
        password: password,
      ),
    );
    return _user!;
  }

  Future<List<UserSession>> fetchSessions() async {
    return runAuthenticated(
      (accessToken) => _repository.fetchSessions(accessToken: accessToken),
    );
  }

  Future<void> deleteMe() async {
    await runAuthenticated(
      (accessToken) => _repository.deleteMe(accessToken: accessToken),
    );
    await clearSession();
    _initialized = true;
  }

  Future<void> revokeSession(String sessionId) async {
    await runAuthenticated(
      (accessToken) => _repository.revokeSession(
        accessToken: accessToken,
        sessionId: sessionId,
      ),
    );
  }

  Future<void> revokeAllSessions() async {
    await runAuthenticated(
      (accessToken) => _repository.revokeAllSessions(accessToken: accessToken),
    );
    await clearSession();
    _initialized = true;
  }

  Future<ApiMessageResponse> forgotPassword({required String email}) {
    return _repository.forgotPassword(email: email);
  }

  Future<ApiMessageResponse> resetPassword({
    required String token,
    required String password,
  }) {
    return _repository.resetPassword(token: token, password: password);
  }

  Future<ApiMessageResponse> verifyEmail({
    String? token,
    String? code,
  }) {
    return _repository.verifyEmail(token: token, code: code);
  }

  Future<ApiMessageResponse> resendVerification() async {
    return runAuthenticated(
      (accessToken) => _repository.resendVerification(accessToken: accessToken),
    );
  }

  Future<void> clearSession() async {
    _user = null;
    await _tokenStore.clear();
  }

  Future<AuthTokens> _requireTokens() async {
    final tokens = await _tokenStore.read();

    if (tokens == null ||
        !tokens.isComplete ||
        _isTokenExpired(tokens.refreshToken)) {
      await clearSession();
      throw const AuthApiException(
        message: 'Connecte-toi pour continuer.',
        statusCode: 401,
      );
    }

    return tokens;
  }

  Future<void> _saveSession(AuthSession session) async {
    if (session.tokens == null || !session.tokens!.isComplete) {
      throw const AuthApiException(
        message:
            'Session mobile incomplete: tokens absents de la reponse API.',
      );
    }

    _user = session.user;
    _initialized = true;
    await _tokenStore.write(session.tokens!);
  }

  AuthTokens? _tokensFromRefresh(ApiMessageResponse response) {
    final accessToken = response.accessToken;
    final refreshToken = response.refreshToken;

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<AuthTokens?> _refreshTokens({String? refreshToken}) async {
    if (_refreshRequest != null) {
      return await _refreshRequest!;
    }

    _refreshRequest = _refreshTokensOnce(refreshToken: refreshToken);

    try {
      return await _refreshRequest!;
    } finally {
      _refreshRequest = null;
    }
  }

  Future<AuthTokens?> _refreshTokensOnce({String? refreshToken}) async {
    final currentTokens = await _tokenStore.read();
    final token = refreshToken ?? currentTokens?.refreshToken;

    if (token == null || token.isEmpty) {
      await clearSession();
      return null;
    }

    try {
      final refreshed = await _repository.refresh(refreshToken: token);
      final nextTokens = _tokensFromRefresh(refreshed);

      if (nextTokens == null || !nextTokens.isComplete) {
        await clearSession();
        return null;
      }

      await _tokenStore.write(nextTokens);
      return nextTokens;
    } on AuthApiException catch (error) {
      if (error.statusCode == 400 || error.statusCode == 401) {
        await clearSession();
        return null;
      }

      rethrow;
    }
  }

  AuthUser? _userFromToken(String token) {
    if (_isTokenExpired(token)) return null;

    try {
      final payload = _payloadFromToken(token);

      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final id = payload['id'];
      final email = payload['email'];
      if (id is! String || id.isEmpty || email is! String || email.isEmpty) {
        return null;
      }

      return AuthUser(
        id: id,
        email: email,
        role: _roleFromToken(payload['role']),
        emailVerified: payload['emailVerified'] == true,
      );
    } on FormatException {
      return null;
    }
  }

  AuthRole _roleFromToken(Object? value) {
    if (value is String && value.toUpperCase() == 'ADMIN') {
      return AuthRole.admin;
    }

    return AuthRole.user;
  }

  bool _isTokenExpired(String token) {
    final payload = _payloadFromToken(token);
    if (payload is! Map<String, dynamic>) {
      return true;
    }

    final exp = payload['exp'];
    final expiresAt = switch (exp) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };

    if (expiresAt == null) {
      return true;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expiresAt <= now;
  }

  Object? _payloadFromToken(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      return jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
    } on FormatException {
      return null;
    }
  }
}
