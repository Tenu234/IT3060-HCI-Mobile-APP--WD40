import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/doctor_queue_item.dart';
import '../models/dispatch_alert_model.dart';
import '../models/doctor_summary_model.dart';

class DoctorService {
  // Support both Windows/Web desktop and Android emulator
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api/doctor';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000/api/doctor';
    return 'http://localhost:5000/api/doctor';
  }

  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  // 1. DOCTOR CONSULTATION MANAGEMENT CRUD

  // READ: View today's assigned patient consultation queue list
  static Future<List<DoctorQueueItem>> getDailyQueue({String status = 'all', String? search}) async {
    final queryParams = <String, String>{};
    if (status != 'all') queryParams['status'] = status;
    if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

    final uri = Uri.parse('$_baseUrl/queue').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => DoctorQueueItem.fromJson(e)).toList();
    }
    throw Exception('Failed to load consultation queue: ${response.body}');
  }

  // UPDATE: Update patient status to "In Consultation" or "Completed"
  static Future<DoctorQueueItem> updatePatientStatus(
    String id,
    String status, {
    String roomNumber = 'Consultation Room 2',
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/queue/$id/status'),
      headers: _headers,
      body: jsonEncode({
        'status': status,
        'roomNumber': roomNumber,
      }),
    );

    if (response.statusCode == 200) {
      return DoctorQueueItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update patient status: ${response.body}');
  }

  // CREATE: Add clinical notes, diagnosis remarks, or prescription details per appointment
  static Future<DoctorQueueItem> saveConsultationNotes(
    String id, {
    required String clinicalNotes,
    required String diagnosis,
    required String prescription,
    bool markCompleted = false,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/queue/$id/notes'),
      headers: _headers,
      body: jsonEncode({
        'clinicalNotes': clinicalNotes,
        'diagnosis': diagnosis,
        'prescription': prescription,
        'markCompleted': markCompleted,
      }),
    );

    if (response.statusCode == 200) {
      return DoctorQueueItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to save consultation notes: ${response.body}');
  }

  // DELETE: Dismiss/skip absent or non-responsive patients from immediate active queue
  static Future<void> skipPatient(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/queue/$id/skip'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to skip patient: ${response.body}');
    }
  }

  // Recall patient back to waiting queue
  static Future<void> recallPatient(String id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/queue/$id/recall'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to recall patient: ${response.body}');
    }
  }

  // 2. DOCTOR REPORTS & COMPLETED SUMMARY
  static Future<DoctorSummaryModel> getDoctorSummary() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reports/summary'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return DoctorSummaryModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load doctor summary reports: ${response.body}');
  }

  // 3. PATIENT NOTIFICATION & ALERT DISPATCH CRUD

  // CREATE: Trigger real-time queue call notifications ("Token A-104 enter Consultation Room 2")
  static Future<DispatchAlertModel> createDispatchAlert({
    required String tokenNumber,
    String? patientName,
    String roomNumber = 'Consultation Room 2',
    String? message,
    String alertType = 'queue_call',
    String priority = 'normal',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/alerts'),
      headers: _headers,
      body: jsonEncode({
        'tokenNumber': tokenNumber,
        'patientName': patientName ?? 'Patient',
        'roomNumber': roomNumber,
        'message': message ?? '$tokenNumber please enter $roomNumber',
        'alertType': alertType,
        'priority': priority,
      }),
    );

    if (response.statusCode == 201) {
      return DispatchAlertModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to dispatch alert: ${response.body}');
  }

  // READ: View notification dispatch logs
  static Future<List<DispatchAlertModel>> getDispatchAlerts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/alerts'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => DispatchAlertModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load dispatch alerts: ${response.body}');
  }

  // DELETE: Clear or dismiss sent notification items
  static Future<void> deleteDispatchAlert(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/alerts/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to dismiss alert: ${response.body}');
    }
  }
}
