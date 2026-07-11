import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_models.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_repository.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_token_store.dart';

void main() {
  test('runAuthenticated refreshes tokens and retries after a 401', () async {
    final tokenStore = _MemoryTokenStore(
      AuthTokens(
        accessToken: _unsignedJwt({
          'id': 'user-1',
          'email': 'benja@example.com',
          'role': 'USER',
        }),
        refreshToken: _unsignedJwt({
          'id': 'user-1',
          'email': 'benja@example.com',
          'role': 'USER',
        }),
      ),
    );
    final repository = _FakeAuthRepository(
      refreshResponse: const ApiMessageResponse(
        message: 'ok',
        accessToken: 'fresh-access',
        refreshToken: 'fresh-refresh',
      ),
    );
    final sessionManager = AuthSessionManager(
      repository: repository,
      tokenStore: tokenStore,
    );

    var attempts = 0;
    final result = await sessionManager.runAuthenticated((accessToken) async {
      attempts += 1;
      if (attempts == 1) {
        throw const AuthApiException(message: 'expired', statusCode: 401);
      }

      return accessToken;
    });

    expect(result, 'fresh-access');
    expect(attempts, 2);
    expect(repository.refreshCalls, 1);
    expect(tokenStore.tokens?.accessToken, 'fresh-access');
    expect(tokenStore.tokens?.refreshToken, 'fresh-refresh');
  });

  test('runAuthenticated keeps stored tokens when refresh has a network error',
      () async {
    final tokenStore = _MemoryTokenStore(
      AuthTokens(
        accessToken: _unsignedJwt({
          'id': 'user-1',
          'email': 'benja@example.com',
          'role': 'USER',
        }),
        refreshToken: _unsignedJwt({
          'id': 'user-1',
          'email': 'benja@example.com',
          'role': 'USER',
        }),
      ),
    );
    final repository = _FakeAuthRepository(
      refreshError: const AuthApiException(message: 'network'),
    );
    final sessionManager = AuthSessionManager(
      repository: repository,
      tokenStore: tokenStore,
    );

    await expectLater(
      sessionManager.runAuthenticated<String>((_) async {
        throw const AuthApiException(message: 'expired', statusCode: 401);
      }),
      throwsA(isA<AuthApiException>()),
    );

    expect(tokenStore.tokens?.accessToken, isNotNull);
    expect(tokenStore.tokens?.refreshToken, isNotNull);
  });

  test('restoreSession keeps a stored session when fetchMe has a server error',
      () async {
    final accessToken = _unsignedJwt({
      'id': 'user-1',
      'email': 'benja@example.com',
      'role': 'USER',
    });
    final tokenStore = _MemoryTokenStore(
      AuthTokens(
        accessToken: accessToken,
        refreshToken: _unsignedJwt({
          'id': 'user-1',
          'email': 'benja@example.com',
          'role': 'USER',
        }),
      ),
    );
    final repository = _FakeAuthRepository(
      fetchMeError: const AuthApiException(
        message: 'server error',
        statusCode: 500,
      ),
    );
    final sessionManager = AuthSessionManager(
      repository: repository,
      tokenStore: tokenStore,
    );

    await expectLater(
      sessionManager.restoreSession(),
      throwsA(isA<AuthApiException>()),
    );

    expect(sessionManager.isAuthenticated, isTrue);
    expect(sessionManager.user?.id, 'user-1');
    expect(sessionManager.user?.email, 'benja@example.com');
    expect(tokenStore.tokens?.accessToken, accessToken);
    expect(tokenStore.tokens?.refreshToken, isNotNull);
  });

  test('restoreSession refreshes immediately when access token is expired',
      () async {
    final expiredAccessToken = _unsignedJwt({
      'id': 'user-1',
      'email': 'benja@example.com',
      'role': 'USER',
      'exp': _timestampSeconds(offset: const Duration(minutes: -1)),
    });
    final tokenStore = _MemoryTokenStore(
      AuthTokens(
        accessToken: expiredAccessToken,
        refreshToken: _unsignedJwt({
          'id': 'user-1',
          'email': 'benja@example.com',
          'role': 'USER',
        }),
      ),
    );
    final repository = _FakeAuthRepository(
      refreshResponse: const ApiMessageResponse(
        message: 'ok',
        accessToken: 'fresh-access',
        refreshToken: 'fresh-refresh',
      ),
    );
    final sessionManager = AuthSessionManager(
      repository: repository,
      tokenStore: tokenStore,
    );

    final user = await sessionManager.restoreSession();

    expect(user?.id, 'user-1');
    expect(repository.refreshCalls, 1);
    expect(tokenStore.tokens?.accessToken, 'fresh-access');
    expect(tokenStore.tokens?.refreshToken, 'fresh-refresh');
  });

  test('restoreSession clears session when refresh token is expired', () async {
    final tokenStore = _MemoryTokenStore(
      AuthTokens(
        accessToken: _unsignedJwt({
          'id': 'user-1',
          'email': 'benja@example.com',
          'role': 'USER',
        }),
        refreshToken: _unsignedJwt({
          'id': 'user-1',
          'email': 'benja@example.com',
          'role': 'USER',
          'exp': _timestampSeconds(offset: const Duration(minutes: -1)),
        }),
      ),
    );
    final sessionManager = AuthSessionManager(
      repository: _FakeAuthRepository(),
      tokenStore: tokenStore,
    );

    final user = await sessionManager.restoreSession();

    expect(user, isNull);
    expect(sessionManager.isAuthenticated, isFalse);
    expect(tokenStore.tokens, isNull);
  });

  test('restoreSession does not authenticate when expired access refresh fails',
      () async {
    final tokenStore = _MemoryTokenStore(
      AuthTokens(
        accessToken: _unsignedJwt({
          'id': 'user-1',
          'email': 'benja@example.com',
          'role': 'USER',
          'exp': _timestampSeconds(offset: const Duration(minutes: -1)),
        }),
        refreshToken: _unsignedJwt({
          'id': 'user-1',
          'email': 'benja@example.com',
          'role': 'USER',
        }),
      ),
    );
    final repository = _FakeAuthRepository(
      refreshError: const AuthApiException(
        message: 'server error',
        statusCode: 500,
      ),
    );
    final sessionManager = AuthSessionManager(
      repository: repository,
      tokenStore: tokenStore,
    );

    await expectLater(
      sessionManager.restoreSession(),
      throwsA(isA<AuthApiException>()),
    );

    expect(sessionManager.isAuthenticated, isFalse);
    expect(tokenStore.tokens, isNotNull);
  });
}

class _MemoryTokenStore implements AuthTokenStore {
  _MemoryTokenStore(this.tokens);

  AuthTokens? tokens;

  @override
  Future<void> clear() async {
    tokens = null;
  }

  @override
  Future<AuthTokens?> read() async {
    return tokens;
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    this.tokens = tokens;
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({
    this.refreshResponse,
    this.refreshError,
    this.fetchMeError,
  });

  final ApiMessageResponse? refreshResponse;
  final AuthApiException? refreshError;
  final AuthApiException? fetchMeError;
  int refreshCalls = 0;

  @override
  Future<AuthUser> fetchMe({required String accessToken}) async {
    final error = fetchMeError;
    if (error != null) {
      throw error;
    }

    return const AuthUser(
      id: 'user-1',
      email: 'benja@example.com',
      role: AuthRole.user,
      emailVerified: true,
    );
  }

  @override
  Future<ApiMessageResponse> refresh({String? refreshToken}) async {
    refreshCalls += 1;

    final error = refreshError;
    if (error != null) {
      throw error;
    }

    return refreshResponse ??
        const ApiMessageResponse(
          message: 'ok',
          accessToken: 'access',
          refreshToken: 'refresh',
        );
  }
}

String _unsignedJwt(Map<String, Object?> payload) {
  final header = _base64UrlJson({'alg': 'none', 'typ': 'JWT'});
  final body = _base64UrlJson({
    'exp': _timestampSeconds(offset: const Duration(hours: 1)),
    ...payload,
  });
  return '$header.$body.signature';
}

String _base64UrlJson(Map<String, Object?> json) {
  return base64Url
      .encode(utf8.encode(jsonEncode(json)))
      .replaceAll('=', '');
}

int _timestampSeconds({required Duration offset}) {
  return DateTime.now().add(offset).millisecondsSinceEpoch ~/ 1000;
}
