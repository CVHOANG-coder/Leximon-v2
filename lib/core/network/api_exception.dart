import 'dart:convert';

/// Error returned when a request cannot be completed or the API returns a
/// non-success status code.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.uri,
    this.body,
  });

  factory ApiException.fromResponse({
    required int statusCode,
    required Uri uri,
    required String body,
  }) {
    var message = 'Request failed with status code $statusCode.';

    if (body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final apiMessage = decoded['message'] ?? decoded['error'];
          if (apiMessage is String && apiMessage.trim().isNotEmpty) {
            message = apiMessage;
          }
        }
      } on FormatException {
        // Keep the status-based message when the server body is not JSON.
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      uri: uri,
      body: body,
    );
  }

  final String message;
  final int? statusCode;
  final Uri? uri;
  final String? body;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' ($statusCode)';
    return 'ApiException$status: $message';
  }
}
