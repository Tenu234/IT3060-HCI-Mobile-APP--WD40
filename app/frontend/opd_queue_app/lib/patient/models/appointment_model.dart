class AppointmentModel {
  final String id;
  final String hospitalName;
  final String opdName;
  final String doctorName;
  final String date;
  final String timeSlot;
  final String status;
  final String tokenNumber;
  final String roomNumber;
  final String patientName;

  AppointmentModel({
    required this.id,
    required this.hospitalName,
    required this.opdName,
    required this.doctorName,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.tokenNumber = '',
    this.roomNumber = 'Consultation Room 2',
    this.patientName = '',
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id:           json['_id']?.toString() ?? json['id']?.toString() ?? '',
      hospitalName: json['hospitalName'] ?? '',
      opdName:      json['opdName'] ?? '',
      doctorName:   json['doctorName'] ?? '',
      date:         json['date'] ?? '',
      timeSlot:     json['timeSlot'] ?? '',
      status:       json['status'] ?? 'waiting',
      tokenNumber:  json['tokenNumber']?.toString() ?? '',
      roomNumber:   json['roomNumber'] ?? 'Consultation Room 2',
      patientName:  json['patientName'] ?? '',
    );
  }
}
