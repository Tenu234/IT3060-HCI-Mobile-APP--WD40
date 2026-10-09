import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lab_report_model.dart';

class LabReportService {
  static const bool _useMock = true; // set false when backend is running
  static const String _baseUrl = 'http://localhost:5000/api/lab-reports';
  static String? _token;

  static void setToken(String token) => _token = token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  static final List<LabReportModel> _mockReports = [
    LabReportModel(
      id: 'L001',
      reportName: 'Full Blood Count',
      category: 'Blood Test',
      testDate: '2026-09-10',
      notes: 'Routine check',
      documentUrl: '',
    ),
  ];

  static Future<List<LabReportModel>> getAll({String? category}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (category == null) return List.from(_mockReports);
      return _mockReports.where((r) => r.category == category).toList();
    }
    final uri = category != null
        ? Uri.parse('$_baseUrl?category=${Uri.encodeComponent(category)}')
        : Uri.parse(_baseUrl);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => LabReportModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load lab reports.');
  }

  static Future<LabReportModel> create({
    required String reportName,
    required String category,
    required String testDate,
    required String notes,
    required String documentUrl,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final r = LabReportModel(
        id: 'L${DateTime.now().millisecondsSinceEpoch}',
        reportName: reportName, category: category,
        testDate: testDate, notes: notes, documentUrl: documentUrl,
      );
      _mockReports.add(r);
      return r;
    }
    final response = await http.post(Uri.parse(_baseUrl), headers: _headers,
        body: jsonEncode({
          'reportName': reportName, 'category': category,
          'testDate': testDate, 'notes': notes, 'documentUrl': documentUrl,
        }));
    if (response.statusCode == 201) return LabReportModel.fromJson(jsonDecode(response.body));
    throw Exception('Failed to add report.');
  }

  static Future<LabReportModel> update({
    required String id, required String reportName, required String category,
    required String testDate, required String notes, required String documentUrl,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final i = _mockReports.indexWhere((r) => r.id == id);
      final updated = LabReportModel(id: id, reportName: reportName,
          category: category, testDate: testDate, notes: notes, documentUrl: documentUrl);
      if (i != -1) _mockReports[i] = updated;
      return updated;
    }
    final response = await http.put(Uri.parse('$_baseUrl/$id'), headers: _headers,
        body: jsonEncode({
          'reportName': reportName, 'category': category,
          'testDate': testDate, 'notes': notes, 'documentUrl': documentUrl,
        }));
    if (response.statusCode == 200) return LabReportModel.fromJson(jsonDecode(response.body));
    throw Exception('Failed to update report.');
  }

  static Future<void> delete(String id) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockReports.removeWhere((r) => r.id == id);
      return;
    }
    await http.delete(Uri.parse('$_baseUrl/$id'), headers: _headers);
  }
}
