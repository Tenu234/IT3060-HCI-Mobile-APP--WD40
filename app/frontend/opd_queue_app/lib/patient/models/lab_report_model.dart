class LabReportModel {
  final String id;
  final String reportName;
  final String category;
  final String testDate;
  final String notes;
  final String documentUrl;

  LabReportModel({
    required this.id,
    required this.reportName,
    required this.category,
    required this.testDate,
    required this.notes,
    required this.documentUrl,
  });

  factory LabReportModel.fromJson(Map<String, dynamic> json) {
    return LabReportModel(
      id:          json['_id']?.toString() ?? '',
      reportName:  json['reportName'] ?? '',
      category:    json['category'] ?? 'Other',
      testDate:    json['testDate'] ?? '',
      notes:       json['notes'] ?? '',
      documentUrl: json['documentUrl'] ?? '',
    );
  }
}
