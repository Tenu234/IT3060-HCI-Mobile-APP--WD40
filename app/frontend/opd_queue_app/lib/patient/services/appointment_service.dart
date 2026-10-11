import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appointment_model.dart';

class AppointmentService {
  static const bool _useMock = true; // set false when backend is running
  static const String _baseUrl = 'http://localhost:5000/api/appointments';
  static String? _token;

  static void setToken(String token) => _token = token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  // Mock data for testing without backend
  static final List<AppointmentModel> _mockAppointments = [
    AppointmentModel(
      id: 'A001',
      hospitalName: 'City General Hospital',
      opdName: 'Cardiology OPD',
      doctorName: 'Dr. Perera',
      date: '2026-10-15',
      timeSlot: '09:00 AM',
      status: 'upcoming',
    ),
    AppointmentModel(
      id: 'A002',
      hospitalName: 'National Hospital',
      opdName: 'Neurology OPD',
      doctorName: 'Dr. Silva',
      date: '2026-09-20',
      timeSlot: '11:00 AM',
      status: 'completed',
    ),
  ];

  static Future<List<AppointmentModel>> getMyAppointments() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return List.from(_mockAppointments);
    }
    final response = await http.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => AppointmentModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load appointments.');
  }

  static Future<void> bookAppointment(AppointmentModel appointment) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockAppointments.add(appointment);
      return;
    }
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
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final i = _mockAppointments.indexWhere((a) => a.id == id);
      if (i != -1) {
        final a = _mockAppointments[i];
        _mockAppointments[i] = AppointmentModel(
          id: a.id, hospitalName: a.hospitalName, opdName: a.opdName,
          doctorName: a.doctorName, date: a.date, timeSlot: a.timeSlot,
          status: 'cancelled',
        );
      }
      return;
    }
    await http.patch(Uri.parse('$_baseUrl/$id/cancel'), headers: _headers);
  }

  static Future<void> rescheduleAppointment(String id, String newDate, String newSlot) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final i = _mockAppointments.indexWhere((a) => a.id == id);
      if (i != -1) {
        final a = _mockAppointments[i];
        _mockAppointments[i] = AppointmentModel(
          id: a.id, hospitalName: a.hospitalName, opdName: a.opdName,
          doctorName: a.doctorName, date: newDate, timeSlot: newSlot,
          status: 'upcoming',
        );
      }
      return;
    }
    await http.patch(
      Uri.parse('$_baseUrl/$id/reschedule'),
      headers: _headers,
      body: jsonEncode({'date': newDate, 'timeSlot': newSlot}),
    );
  }
}
