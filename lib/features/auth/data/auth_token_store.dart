import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_models.dart';

abstract class AuthTokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

class SecureAuthTokenStore implements AuthTokenStore {
  const SecureAuthTokenStore({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  }) : this._(secureStorage);

  const SecureAuthTokenStore._(this._secureStorage);

  static const _accessTokenKey = 'rugby_jam_access_token';
  static const _refreshTokenKey = 'rugby_jam_refresh_token';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<AuthTokens?> read() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _secureStorage.write(
      key: _accessTokenKey,
      value: tokens.accessToken,
    );
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: tokens.refreshToken,
    );
  }

  @override
  Future<void> clear() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }
}
