import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_models.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_repository.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_token_store.dart';

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

    try {
      _user = await _repository.fetchMe(accessToken: tokens.accessToken);
      return _user;
    } on AuthApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }

      return refreshSession(refreshToken: tokens.refreshToken);
    } finally {
      _initialized = true;
    }
  }

  Future<AuthUser?> refreshSession({String? refreshToken}) async {
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
      _user = await _repository.fetchMe(accessToken: nextTokens.accessToken);
      return _user;
    } on AuthApiException {
      await clearSession();
      return null;
    } finally {
      _initialized = true;
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

  Future<String?> readAccessToken() async {
    final tokens = await _tokenStore.read();
    return tokens?.accessToken;
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
    final tokens = await _tokenStore.read();

    if (tokens == null || tokens.accessToken.isEmpty) {
      throw const AuthApiException(
        message: 'Connecte-toi pour renvoyer le lien de verification.',
        statusCode: 401,
      );
    }

    return _repository.resendVerification(accessToken: tokens.accessToken);
  }

  Future<void> clearSession() async {
    _user = null;
    await _tokenStore.clear();
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
}
