import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  ApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> healthCheck() async {
    final uri = Uri.parse('$baseUrl/health');
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode >= 400) {
      throw ApiException('Backend health check failed.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitTextQuery(String query) async {
    final uri = Uri.parse('$baseUrl/query');
    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'query': query}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 400) {
      throw ApiException(
        _readErrorMessage(
          response,
          fallback: 'The assistant service could not process this request.',
        ),
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitVisionQuery({
    required String query,
    required List<int> imageBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/query');
    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': query,
            'imageBase64': base64Encode(imageBytes),
            'mimeType': 'image/jpeg',
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode >= 400) {
      throw ApiException(
        _readErrorMessage(
          response,
          fallback: 'The vision assistant could not process this request.',
        ),
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _readErrorMessage(
    http.Response response, {
    required String fallback,
  }) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'] ?? body['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } on FormatException {
      return fallback;
    }

    return fallback;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
