class AppointmentModel {
  final String id;
  final String hospitalName;
  final String opdName;
  final String doctorName;
  final String date;
  final String timeSlot;
  final String status;

  AppointmentModel({
    required this.id,
    required this.hospitalName,
    required this.opdName,
    required this.doctorName,
    required this.date,
    required this.timeSlot,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id:           json['_id']?.toString() ?? '',
      hospitalName: json['hospitalName'] ?? '',
      opdName:      json['opdName'] ?? '',
      doctorName:   json['doctorName'] ?? '',
      date:         json['date'] ?? '',
      timeSlot:     json['timeSlot'] ?? '',
      status:       json['status'] ?? 'upcoming',
    );
  }
}
