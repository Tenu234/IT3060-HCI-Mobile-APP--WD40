import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiException implements Exception {
  final String message;
  final int status;
  final Map<String, String> fields;
  final bool needsConfirmation;
  ApiException(this.message,
      {this.status = 0, this.fields = const {}, this.needsConfirmation = false});
  @override
  String toString() => message;
}

class Api {
  Api._();
  static final Api i = Api._();

  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> get(String path, [Map<String, String>? query]) =>
      _send('GET', path, query: query);
  Future<Map<String, dynamic>> post(String path, [Object? body]) => _send('POST', path, body: body);
  Future<Map<String, dynamic>> put(String path, [Object? body]) => _send('PUT', path, body: body);
  Future<Map<String, dynamic>> patch(String path, [Object? body]) => _send('PATCH', path, body: body);
  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(String method, String path,
      {Map<String, String>? query, Object? body}) async {
    final uri = Uri.parse('$apiBase/api$path').replace(queryParameters: query);
    try {
      late http.Response res;
      final encoded = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'GET':
          res = await http.get(uri, headers: _headers);
          break;
        case 'POST':
          res = await http.post(uri, headers: _headers, body: encoded);
          break;
        case 'PUT':
          res = await http.put(uri, headers: _headers, body: encoded);
          break;
        case 'PATCH':
          res = await http.patch(uri, headers: _headers, body: encoded);
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: _headers);
          break;
      }
      final Map<String, dynamic> data =
          res.body.isEmpty ? {} : (jsonDecode(res.body) as Map<String, dynamic>);
      if (res.statusCode >= 200 && res.statusCode < 300) return data;

      final fields = <String, String>{};
      if (data['fields'] is Map) {
        (data['fields'] as Map).forEach((k, v) => fields[k.toString()] = v.toString());
      }
      throw ApiException(
        (data['error'] ?? 'Request failed (${res.statusCode}).').toString(),
        status: res.statusCode,
        fields: fields,
        needsConfirmation: data['needs_confirmation'] == true,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Try again.');
    } catch (_) {
      throw ApiException('Cannot reach the server. Check your connection and that the API is running.');
    }
  }
}
