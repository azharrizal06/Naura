import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Lempar error ini saat API mengembalikan status non-2xx.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException(this.statusCode, this.message, {this.errors});

  @override
  String toString() => message;
}

/// HTTP client tipis untuk REST API Laravel.
class ApiClient {
  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 15)})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Batas tunggu tiap permintaan; lewat batas → TimeoutException
  /// (server mati / tidak terjangkau tidak boleh membuat layar menggantung).
  final Duration timeout;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (query == null || query.isEmpty) return uri;
    final params = <String, String>{};
    query.forEach((key, value) {
      if (value != null) params[key] = value.toString();
    });
    return uri.replace(queryParameters: {...uri.queryParameters, ...params});
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _client.get(_uri(path, query), headers: _headers).timeout(timeout);
    return _handle(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final res = await _client
        .post(
          _uri(path),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
    return _handle(res);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final res = await _client
        .patch(
          _uri(path),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
    return _handle(res);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final res = await _client
        .put(
          _uri(path),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _client.delete(_uri(path), headers: _headers).timeout(timeout);
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    final dynamic data =
        res.body.isNotEmpty ? jsonDecode(res.body) : <String, dynamic>{};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    throw ApiException(
      res.statusCode,
      (map['message'] ?? 'Terjadi kesalahan (${res.statusCode}).') as String,
      errors: map['errors'] as Map<String, dynamic>?,
    );
  }
}
