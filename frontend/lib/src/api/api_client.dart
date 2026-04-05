import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../debug/debug_log.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({required TokenStorage tokenStorage}) : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  Uri _uri(String path) => Uri.parse('${FitnetConfig.apiBaseUrl}$path');

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await _tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final uri = _uri(path);
    DebugLog.add('api', 'POST $uri', details: _redactBody(body));
    final res = await http.post(uri, headers: await _headers(auth: auth), body: jsonEncode(body));
    DebugLog.add('api', '← ${res.statusCode} POST $uri', details: _truncate(res.body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> getJson(String path, {bool auth = true}) async {
    final uri = _uri(path);
    DebugLog.add('api', 'GET $uri');
    final res = await http.get(uri, headers: await _headers(auth: auth));
    DebugLog.add('api', '← ${res.statusCode} GET $uri', details: _truncate(res.body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body) async {
    final uri = _uri(path);
    DebugLog.add('api', 'PUT $uri', details: _redactBody(body));
    final res = await http.put(uri, headers: await _headers(), body: jsonEncode(body));
    DebugLog.add('api', '← ${res.statusCode} PUT $uri', details: _truncate(res.body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final uri = _uri(path);
    DebugLog.add('api', 'DELETE $uri');
    final res = await http.delete(uri, headers: await _headers());
    DebugLog.add('api', '← ${res.statusCode} DELETE $uri', details: _truncate(res.body));
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final text = res.body;
    final dynamic decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    }
    final message = decoded is Map<String, dynamic>
        ? (decoded['message']?.toString() ?? 'Request failed')
        : 'Request failed';
    throw ApiException(statusCode: res.statusCode, message: message, body: decoded);
  }

  static Object _truncate(String body, {int max = 2000}) {
    if (body.length <= max) return body;
    return '${body.substring(0, max)}\n... (truncated ${body.length - max} chars)';
  }

  static Map<String, dynamic> _redactBody(Map<String, dynamic> body) {
    final copy = Map<String, dynamic>.from(body);
    if (copy.containsKey('password')) copy['password'] = '***';
    if (copy.containsKey('token')) copy['token'] = '***';
    return copy;
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message, this.body});

  final int statusCode;
  final String message;
  final dynamic body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

