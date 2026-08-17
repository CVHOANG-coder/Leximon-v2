import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'api_response.dart';

typedef AuthTokenLoader = Future<String?> Function();
typedef AuthTokenRefresher = Future<String?> Function();

/// Shared HTTP client for the Leximon backend.
class ApiClient {
  ApiClient({
    http.Client? client,
    this.baseUrl = defaultBaseUrl,
    this.requestTimeout = const Duration(seconds: 30),
    String? authToken,
    AuthTokenLoader? tokenLoader,
  }) : _client = client ?? http.Client(),
       _authToken = authToken,
       _tokenLoader = tokenLoader;

  static const defaultBaseUrl = 'https://leximonenglish.giddychat.com';

  final http.Client _client;
  final String baseUrl;
  final Duration requestTimeout;
  final AuthTokenLoader? _tokenLoader;
  String? _authToken;
  bool _tokenLoaded = false;
  AuthTokenRefresher? _tokenRefresher;
  Future<String?>? _refreshFuture;

  String? get authToken => _authToken;

  void setAuthToken(String token) {
    final value = token.trim();
    _authToken = value.isEmpty ? null : value;
  }

  void clearAuthToken() => _authToken = null;

  void setTokenRefresher(AuthTokenRefresher refresher) {
    _tokenRefresher = refresher;
  }

  Future<void> loadStoredAuthToken() async {
    if (_tokenLoaded) return;
    _tokenLoaded = true;
    final token = await _tokenLoader?.call();
    if (token?.trim().isNotEmpty == true) {
      _authToken = token!.trim();
    }
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _request(method: 'POST', path: path, body: body, headers: headers);
  }

  Future<ApiResponse> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _request(method: 'PUT', path: path, body: body, headers: headers);
  }

  Future<ApiResponse> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _request(method: 'DELETE', path: path, body: body, headers: headers);
  }

  void close() => _client.close();

  Future<ApiResponse> _request({
    required String method,
    required String path,
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _resolve(path, queryParameters);
    await loadStoredAuthToken();
    return _requestWithRetry(
      method: method,
      path: path,
      uri: uri,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      retryOnUnauthorized: true,
    );
  }

  Future<ApiResponse> _requestWithRetry({
    required String method,
    required String path,
    required Uri uri,
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    required bool retryOnUnauthorized,
  }) async {
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (!_isLoginPath(uri) && _authToken?.isNotEmpty == true)
        'Authorization': 'Bearer $_authToken',
      ...?headers,
    };

    try {
      final request = http.Request(method, uri)..headers.addAll(requestHeaders);
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse = await _client
          .send(request)
          .timeout(requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final exception = ApiException.fromResponse(
          statusCode: response.statusCode,
          uri: uri,
          body: response.body,
        );
        if (retryOnUnauthorized &&
            (response.statusCode == 401 || response.statusCode == 403) &&
            !_isLoginPath(uri) &&
            _tokenRefresher != null) {
          final refreshedToken = await _refreshAuthToken();
          if (refreshedToken?.isNotEmpty == true) {
            return _requestWithRetry(
              method: method,
              path: path,
              uri: uri,
              body: body,
              queryParameters: queryParameters,
              headers: headers,
              retryOnUnauthorized: false,
            );
          }
        }
        throw exception;
      }

      return ApiResponse.fromHttpResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(message: 'The request timed out.', uri: uri);
    } on Object catch (error) {
      throw ApiException(
        message: 'The request could not be completed: $error',
        uri: uri,
      );
    }
  }

  Future<String?> _refreshAuthToken() async {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _tokenRefresher!();
    _refreshFuture = refresh;
    try {
      final token = await refresh;
      if (token?.trim().isNotEmpty == true) setAuthToken(token!);
      return token;
    } finally {
      if (identical(_refreshFuture, refresh)) _refreshFuture = null;
    }
  }

  bool _isLoginPath(Uri uri) => uri.path == '/auth/login';

  Uri _resolve(String path, Map<String, String>? queryParameters) {
    final parsed = Uri.parse(path);
    final uri = parsed.hasScheme
        ? parsed
        : Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}');
    return queryParameters == null
        ? uri
        : uri.replace(
            queryParameters: {...uri.queryParameters, ...queryParameters},
          );
  }
}
