import 'dart:convert';
import 'dart:io';

import 'package:rugby_jam_mobile/core/config/api_config.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_models.dart';

class AuthApiClient {
  AuthApiClient({
    HttpClient? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? HttpClient(),
        _baseUri = Uri.parse(baseUrl ?? ApiConfig.baseUrl) {
    _httpClient.connectionTimeout = const Duration(seconds: 10);
  }

  final HttpClient _httpClient;
  final Uri _baseUri;

  static const _clientHeader = 'x-rugbyjam-client';
  static const _clientHeaderValue = 'mobile';

  void close({bool force = false}) {
    _httpClient.close(force: force);
  }

  Future<AuthResponse> login(LoginPayload payload) async {
    final json = await _postJson('/auth/login', body: payload.toJson());
    return AuthResponse.fromJson(json);
  }

  Future<AuthResponse> register(RegisterPayload payload) async {
    final json = await _postJson('/auth/register', body: payload.toJson());
    return AuthResponse.fromJson(json);
  }

  Future<ApiMessageResponse> refresh({String? refreshToken}) async {
    final json = await _postJson(
      '/auth/refresh',
      body: {
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken': refreshToken,
      },
    );
    return ApiMessageResponse.fromJson(json);
  }

  Future<void> logout({
    String? accessToken,
    String? refreshToken,
  }) async {
    await _postJson(
      '/auth/logout',
      accessToken: accessToken,
      body: {
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken': refreshToken,
      },
      allowsEmptyResponse: true,
    );
  }

  Future<ApiMessageResponse> forgotPassword(
    ForgotPasswordPayload payload,
  ) async {
    final json = await _postJson(
      '/auth/forgot-password',
      body: payload.toJson(),
    );
    return ApiMessageResponse.fromJson(json);
  }

  Future<ApiMessageResponse> resetPassword(ResetPasswordPayload payload) async {
    final json = await _postJson(
      '/auth/reset-password',
      body: payload.toJson(),
    );
    return ApiMessageResponse.fromJson(json);
  }

  Future<ApiMessageResponse> verifyEmail(VerifyEmailPayload payload) async {
    final json = await _postJson(
      '/auth/verify-email',
      body: payload.toJson(),
    );
    return ApiMessageResponse.fromJson(json);
  }

  Future<ApiMessageResponse> resendVerification({
    required String accessToken,
  }) async {
    final json = await _postJson(
      '/auth/resend-verification',
      accessToken: accessToken,
    );
    return ApiMessageResponse.fromJson(json);
  }

  Future<AuthUser> fetchMe({required String accessToken}) async {
    final json = await _requestJson(
      method: 'GET',
      path: '/users/me',
      accessToken: accessToken,
    );
    return AuthUser.fromJson(json);
  }

  Future<AuthUser> updateMe({
    required String accessToken,
    required UpdateMePayload payload,
  }) async {
    final json = await _requestJson(
      method: 'PATCH',
      path: '/users/me',
      accessToken: accessToken,
      body: payload.toJson(),
    );
    return AuthUser.fromJson(json);
  }

  Future<void> deleteMe({required String accessToken}) async {
    await _request(
      method: 'DELETE',
      path: '/users/me',
      accessToken: accessToken,
      allowsEmptyResponse: true,
    );
  }

  Future<List<UserSession>> fetchSessions({
    required String accessToken,
  }) async {
    final json = await _request(
      method: 'GET',
      path: '/users/sessions',
      accessToken: accessToken,
    );

    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(UserSession.fromJson)
          .toList();
    }

    throw const AuthApiException(message: 'Reponse API invalide.');
  }

  Future<void> revokeSession({
    required String accessToken,
    required String sessionId,
  }) async {
    await _request(
      method: 'DELETE',
      path: '/users/sessions/$sessionId',
      accessToken: accessToken,
      allowsEmptyResponse: true,
    );
  }

  Future<void> revokeAllSessions({required String accessToken}) async {
    await _request(
      method: 'DELETE',
      path: '/users/sessions',
      accessToken: accessToken,
      allowsEmptyResponse: true,
    );
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    Map<String, dynamic>? body,
    String? accessToken,
    bool allowsEmptyResponse = false,
  }) {
    return _requestJson(
      method: 'POST',
      path: path,
      body: body,
      accessToken: accessToken,
      allowsEmptyResponse: allowsEmptyResponse,
    );
  }

  Future<Map<String, dynamic>> _requestJson({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? accessToken,
    bool allowsEmptyResponse = false,
  }) async {
    final decoded = await _request(
      method: method,
      path: path,
      body: body,
      accessToken: accessToken,
      allowsEmptyResponse: allowsEmptyResponse,
    );

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const AuthApiException(message: 'Reponse API invalide.');
  }

  Future<Object?> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? accessToken,
    bool allowsEmptyResponse = false,
  }) async {
    try {
      final uri = _resolve(path);
      final request = await _httpClient.openUrl(method, uri);

      request.headers.contentType = ContentType.json;
      request.headers.add(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(_clientHeader, _clientHeaderValue);

      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $accessToken',
        );
      }

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < HttpStatus.ok ||
          response.statusCode >= HttpStatus.multipleChoices) {
        throw AuthApiException(
          message: _errorMessageFromBody(responseBody),
          statusCode: response.statusCode,
        );
      }

      if (responseBody.isEmpty) {
        if (allowsEmptyResponse) {
          return const <String, dynamic>{};
        }

        return const <String, dynamic>{};
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic> || decoded is List) {
        return decoded;
      }
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw AuthApiException(message: _networkErrorMessage());
    } on HttpException {
      throw AuthApiException(message: _networkErrorMessage());
    } on FormatException {
      throw const AuthApiException(message: 'Reponse API invalide.');
    }

    throw const AuthApiException(message: 'Reponse API invalide.');
  }

  Uri _resolve(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';

    return _baseUri.replace(path: '$basePath$normalizedPath');
  }

  String _errorMessageFromBody(String responseBody) {
    if (responseBody.isEmpty) {
      return 'Une erreur est survenue.';
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }

        final errors = decoded['errors'];
        if (errors is List && errors.isNotEmpty) {
          final firstError = errors.first;
          if (firstError is Map<String, dynamic>) {
            final errorMessage = firstError['message'];
            if (errorMessage is String && errorMessage.isNotEmpty) {
              return errorMessage;
            }
          }
        }
      }
    } on FormatException {
      return 'Une erreur est survenue.';
    }

    return 'Une erreur est survenue.';
  }

  String _networkErrorMessage() {
    final host = _baseUri.host.toLowerCase();
    if (Platform.isAndroid && (host == 'localhost' || host == '127.0.0.1')) {
      return "API injoignable: sur Android, localhost pointe vers le telephone. Lance l'app avec l'IP locale de ton PC.";
    }

    return "API injoignable. Verifie que le serveur est lance et que l'URL API est correcte.";
  }
}

class AuthApiException implements Exception {
  const AuthApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }

    return '$message ($statusCode)';
  }
}
