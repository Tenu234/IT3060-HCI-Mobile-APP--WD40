import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lab_report_model.dart';

class LabReportService {
  static const String _baseUrl = 'http://localhost:5000/api/lab-reports';
  static String? _token;

  static void setToken(String token) => _token = token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  static Future<List<LabReportModel>> getAll({String? category}) async {
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
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        'reportName': reportName,
        'category': category,
        'testDate': testDate,
        'notes': notes,
        'documentUrl': documentUrl,
      }),
    );
    if (response.statusCode == 201) {
      return LabReportModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to add report.');
  }

  static Future<LabReportModel> update({
    required String id,
    required String reportName,
    required String category,
    required String testDate,
    required String notes,
    required String documentUrl,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
      body: jsonEncode({
        'reportName': reportName,
        'category': category,
        'testDate': testDate,
        'notes': notes,
        'documentUrl': documentUrl,
      }),
    );
    if (response.statusCode == 200) {
      return LabReportModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update report.');
  }

  static Future<void> delete(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete report.');
    }
  }
}
