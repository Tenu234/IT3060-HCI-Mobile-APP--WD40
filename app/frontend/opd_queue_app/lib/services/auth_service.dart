import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../patient/services/appointment_service.dart';
import '../patient/services/lab_report_service.dart';

class AuthService {
  // Toggle this to false when your backend is ready, then set _baseUrl
  static const bool _useMock = false;
  static const String _baseUrl = 'http://localhost:5000/api'; // web/desktop

  // ─── Mock users for testing all 4 roles ───────────────────────────────────
  static final List<Map<String, String>> _mockUsers = [
    {'email': 'patient@test.com',  'password': '123456', 'role': 'patient', 'name': 'Sam Patient',  'id': '1'},
    {'email': 'doctor@test.com',   'password': '123456', 'role': 'doctor',  'name': 'Dr. Smith',    'id': '2'},
    {'email': 'nurse@test.com',    'password': '123456', 'role': 'nurse',   'name': 'Nurse Anna',   'id': '3'},
    {'email': 'admin@test.com',    'password': '123456', 'role': 'admin',   'name': 'Admin Root',   'id': '4'},
    {'email': 'staff@test.com',    'password': '123456', 'role': 'staff',   'name': 'Staff User',   'id': '5'},
  ];

  static Future<UserModel> login(String email, String password) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1)); // simulate network
      final match = _mockUsers.where(
        (u) => u['email'] == email.trim().toLowerCase() && u['password'] == password,
      );
      if (match.isEmpty) {
        throw Exception('Invalid email or password.');
      }
      final u = match.first;
      return UserModel(id: u['id']!, name: u['name']!, email: u['email']!, role: u['role']!, token: 'mock-token');
    }

    // ── Real API call (uncomment when backend is ready) ──
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final user = UserModel.fromJson(data);
      AppointmentService.setToken(user.token);
      LabReportService.setToken(user.token);
      return user;
    }
    throw Exception(data['message'] ?? 'Login failed.');
    // throw Exception('Backend not configured.');
  }

  static Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String nic,
    required String role,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));

      final exists = _mockUsers.any((u) => u['email'] == email.trim().toLowerCase());
      if (exists) {
        throw Exception('Email is already registered.');
      }

      return UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        role: role,
        token: 'mock-token',
      );
    }

    // ── Real API call (uncomment when backend is ready) ──
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'phone': phone, 'nic': nic, 'role': role}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return UserModel.fromJson(data);
    throw Exception(data['message'] ?? 'Registration failed.');
    // throw Exception('Backend not configured.');
  }
}
