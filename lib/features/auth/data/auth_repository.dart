import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_models.dart';

class AuthRepository {
  AuthRepository({
    AuthApiClient? apiClient,
  }) : _apiClient = apiClient ?? AuthApiClient();

  final AuthApiClient _apiClient;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.login(
      LoginPayload(email: email, password: password),
    );
    return _sessionFromResponse(response);
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    String? username,
  }) async {
    final response = await _apiClient.register(
      RegisterPayload(
        email: email,
        password: password,
        username: username,
      ),
    );
    return _sessionFromResponse(response);
  }

  Future<ApiMessageResponse> forgotPassword({required String email}) {
    return _apiClient.forgotPassword(ForgotPasswordPayload(email: email));
  }

  Future<ApiMessageResponse> resetPassword({
    required String token,
    required String password,
  }) {
    return _apiClient.resetPassword(
      ResetPasswordPayload(token: token, password: password),
    );
  }

  Future<ApiMessageResponse> verifyEmail({
    String? token,
    String? code,
  }) {
    return _apiClient.verifyEmail(
      VerifyEmailPayload(
        token: token,
        code: code,
      ),
    );
  }

  Future<ApiMessageResponse> resendVerification({
    required String accessToken,
  }) {
    return _apiClient.resendVerification(accessToken: accessToken);
  }

  Future<AuthUser> fetchMe({required String accessToken}) {
    return _apiClient.fetchMe(accessToken: accessToken);
  }

  Future<ApiMessageResponse> refresh({String? refreshToken}) {
    return _apiClient.refresh(refreshToken: refreshToken);
  }

  Future<void> logout({
    String? accessToken,
    String? refreshToken,
  }) {
    return _apiClient.logout(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  AuthSession _sessionFromResponse(AuthResponse response) {
    final accessToken = response.accessToken;
    final refreshToken = response.refreshToken;

    return AuthSession(
      user: response.user,
      tokens: accessToken == null || refreshToken == null
          ? null
          : AuthTokens(
              accessToken: accessToken,
              refreshToken: refreshToken,
            ),
    );
  }
}
