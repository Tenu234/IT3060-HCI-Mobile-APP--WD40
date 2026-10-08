import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class Auth {
  Auth._();
  static final Auth i = Auth._();

  Map<String, dynamic>? user;

  bool get loggedIn => user != null && Api.i.token != null;
  String get role => (user?['role'] ?? '').toString();

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('token');
    if (t == null) return;
    Api.i.token = t;
    try {
      final r = await Api.i.get('/auth/me');
      user = Map<String, dynamic>.from(r['user'] as Map);
    } on ApiException catch (e) {
      // Only drop the session when the server says it is invalid.
      if (e.status == 401) await logout();
    }
  }

  Future<void> _store(Map<String, dynamic> r) async {
    Api.i.token = r['token'] as String;
    user = Map<String, dynamic>.from(r['user'] as Map);
    final p = await SharedPreferences.getInstance();
    await p.setString('token', Api.i.token!);
    await p.setString('user', jsonEncode(user));
  }

  Future<void> login(String identifier, String password) async {
    final r = await Api.i.post('/auth/login', {'identifier': identifier, 'password': password});
    await _store(r);
  }

  Future<void> register(Map<String, dynamic> body) async {
    final r = await Api.i.post('/auth/register', body);
    await _store(r);
  }

  void updateUser(Map<String, dynamic> u) => user = u;

  Future<void> logout() async {
    Api.i.token = null;
    user = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
    await p.remove('user');
  }
}
