import 'dart:convert';

/// Common response wrapper returned by [ApiClient].
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.data,
  });

  const ApiResponse.raw({
    required this.statusCode,
    required this.headers,
    required this.body,
  }) : data = null;

  factory ApiResponse.fromHttpResponse({
    required int statusCode,
    required Map<String, String> headers,
    required String body,
  }) {
    dynamic data;
    if (body.trim().isNotEmpty) {
      try {
        data = jsonDecode(body);
      } on FormatException {
        data = body;
      }
    }

    return ApiResponse(
      statusCode: statusCode,
      headers: headers,
      body: body,
      data: data,
    );
  }

  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final dynamic data;

  Map<String, dynamic>? get mapData =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : null;
}
