import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appointment_model.dart';

class AppointmentService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api/appointments';

  static String? _token; // set this after login

  static void setToken(String token) => _token = token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  static Future<List<AppointmentModel>> getMyAppointments() async {
    final response = await http.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => AppointmentModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load appointments.');
  }

  static Future<void> bookAppointment(AppointmentModel appointment) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        'hospitalName': appointment.hospitalName,
        'opdName': appointment.opdName,
        'doctorName': appointment.doctorName,
        'date': appointment.date,
        'timeSlot': appointment.timeSlot,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to book appointment.');
    }
  }

  static Future<void> cancelAppointment(String id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$id/cancel'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel appointment.');
    }
  }

  static Future<void> rescheduleAppointment(String id, String newDate, String newSlot) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$id/reschedule'),
      headers: _headers,
      body: jsonEncode({'date': newDate, 'timeSlot': newSlot}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reschedule appointment.');
    }
  }
}
