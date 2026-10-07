class DispatchAlertModel {
  final String id;
  final String tokenNumber;
  final String patientName;
  final String roomNumber;
  final String message;
  final String alertType;
  final String status;
  final String priority;
  final DateTime createdAt;

  DispatchAlertModel({
    required this.id,
    required this.tokenNumber,
    required this.patientName,
    required this.roomNumber,
    required this.message,
    required this.alertType,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory DispatchAlertModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return DispatchAlertModel(
      id: json['_id'] ?? json['id'] ?? '',
      tokenNumber: json['tokenNumber'] ?? '',
      patientName: json['patientName'] ?? 'Patient',
      roomNumber: json['roomNumber'] ?? 'Consultation Room 2',
      message: json['message'] ?? '',
      alertType: json['alertType'] ?? 'queue_call',
      status: json['status'] ?? 'active',
      priority: json['priority'] ?? 'normal',
      createdAt: parseDate(json['createdAt']),
    );
  }
}
