import 'dart:convert';
import 'dart:io';

class ApiErrorMessages {
  const ApiErrorMessages._();

  static String fromResponseBody(String responseBody) {
    if (responseBody.isEmpty) {
      return generic;
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return sanitize(message);
        }
      }
    } on FormatException {
      return generic;
    }

    return generic;
  }

  static String sanitize(String message) {
    final normalizedMessage = message.toLowerCase();

    if (normalizedMessage.contains('missing application key') ||
        normalizedMessage.contains('application key') ||
        normalizedMessage.contains('x-apisports-key')) {
      return 'Service rugby indisponible: la cle API preprod est manquante ou invalide.';
    }

    return message;
  }

  static String network(Uri baseUri) {
    final host = baseUri.host.toLowerCase();
    if (Platform.isAndroid && (host == 'localhost' || host == '127.0.0.1')) {
      return "API injoignable: sur Android, localhost pointe vers le telephone. Lance l'app avec l'IP locale de ton PC.";
    }

    return "API injoignable. Verifie que le serveur est lance et que l'URL API est correcte.";
  }

  static const generic = 'Une erreur est survenue.';
  static const invalidResponse = 'Reponse API invalide.';
}
