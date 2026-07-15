import 'dart:convert';
import 'dart:io';

import 'package:rugby_jam_mobile/core/config/api_config.dart';
import 'package:rugby_jam_mobile/core/network/api_error_messages.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';

class ApiClient {
  ApiClient({
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

  Future<Map<String, dynamic>> getJson(
    String path, {
    required String accessToken,
    Map<String, String>? queryParameters,
  }) async {
    final decoded = await _getDecodedJson(
      path,
      accessToken: accessToken,
      queryParameters: queryParameters,
    );

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw AuthApiException(message: ApiErrorMessages.invalidResponse);
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    required String accessToken,
    Map<String, String>? queryParameters,
  }) async {
    final decoded = await _getDecodedJson(
      path,
      accessToken: accessToken,
      queryParameters: queryParameters,
    );

    if (decoded is List) {
      return decoded;
    }

    throw AuthApiException(message: ApiErrorMessages.invalidResponse);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final decoded = await _sendDecodedJson(
      path,
      method: 'POST',
      accessToken: accessToken,
      body: body,
    );

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw AuthApiException(message: ApiErrorMessages.invalidResponse);
  }

  Future<dynamic> deleteJson(
    String path, {
    required String accessToken,
  }) {
    return _sendDecodedJson(
      path,
      method: 'DELETE',
      accessToken: accessToken,
    );
  }

  Future<dynamic> _getDecodedJson(
    String path, {
    required String accessToken,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = _resolve(path, queryParameters: queryParameters);
      final request = await _httpClient.getUrl(uri);

      request.headers.add(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(_clientHeader, _clientHeaderValue);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      );

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < HttpStatus.ok ||
          response.statusCode >= HttpStatus.multipleChoices) {
        throw AuthApiException(
          message: ApiErrorMessages.fromResponseBody(responseBody),
          statusCode: response.statusCode,
        );
      }

      if (responseBody.isEmpty) {
        return const <String, dynamic>{};
      }

      return jsonDecode(responseBody);
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw AuthApiException(message: ApiErrorMessages.network(_baseUri));
    } on HttpException {
      throw AuthApiException(message: ApiErrorMessages.network(_baseUri));
    } on FormatException {
      throw AuthApiException(message: ApiErrorMessages.invalidResponse);
    }
  }

  Future<dynamic> _sendDecodedJson(
    String path, {
    required String method,
    required String accessToken,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = _resolve(path);
      final request = await _httpClient.openUrl(method, uri);

      request.headers.add(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(_clientHeader, _clientHeaderValue);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      );

      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < HttpStatus.ok ||
          response.statusCode >= HttpStatus.multipleChoices) {
        throw AuthApiException(
          message: ApiErrorMessages.fromResponseBody(responseBody),
          statusCode: response.statusCode,
        );
      }

      if (responseBody.isEmpty) {
        return const <String, dynamic>{};
      }

      return jsonDecode(responseBody);
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw AuthApiException(message: ApiErrorMessages.network(_baseUri));
    } on HttpException {
      throw AuthApiException(message: ApiErrorMessages.network(_baseUri));
    } on FormatException {
      throw AuthApiException(message: ApiErrorMessages.invalidResponse);
    }
  }

  Uri _resolve(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';

    return _baseUri.replace(
      path: '$basePath$normalizedPath',
      queryParameters: queryParameters,
    );
  }
}
