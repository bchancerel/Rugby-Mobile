import 'dart:convert';
import 'dart:io';

import 'package:rugby_jam_mobile/core/config/api_config.dart';
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

    throw const AuthApiException(message: 'Reponse API invalide.');
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

    throw const AuthApiException(message: 'Reponse API invalide.');
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
          message: _errorMessageFromBody(responseBody),
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
      throw AuthApiException(message: _networkErrorMessage());
    } on HttpException {
      throw AuthApiException(message: _networkErrorMessage());
    } on FormatException {
      throw const AuthApiException(message: 'Reponse API invalide.');
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

  String _errorMessageFromBody(String responseBody) {
    if (responseBody.isEmpty) {
      return 'Une erreur est survenue.';
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return _sanitizeApiMessage(message);
        }
      }
    } on FormatException {
      return 'Une erreur est survenue.';
    }

    return 'Une erreur est survenue.';
  }

  String _sanitizeApiMessage(String message) {
    final normalizedMessage = message.toLowerCase();

    if (normalizedMessage.contains('missing application key') ||
        normalizedMessage.contains('application key') ||
        normalizedMessage.contains('x-apisports-key')) {
      return 'Service rugby indisponible: la cle API preprod est manquante ou invalide.';
    }

    return message;
  }

  String _networkErrorMessage() {
    final host = _baseUri.host.toLowerCase();
    if (Platform.isAndroid && (host == 'localhost' || host == '127.0.0.1')) {
      return "API injoignable: sur Android, localhost pointe vers le telephone. Lance l'app avec l'IP locale de ton PC.";
    }

    return "API injoignable. Verifie que le serveur est lance et que l'URL API est correcte.";
  }
}
