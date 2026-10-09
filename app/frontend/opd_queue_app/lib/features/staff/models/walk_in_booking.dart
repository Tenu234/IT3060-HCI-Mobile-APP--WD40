class WalkInBooking {
  final String? id;
  final String patientName;
  final String patientPhone;
  final String doctorName;
  final String roomNumber;
  final String status; // entered_opd, waiting_room, in_consultation, completed, absent, cancelled
  final DateTime createdAt;

  WalkInBooking({
    this.id,
    required this.patientName,
    required this.patientPhone,
    required this.doctorName,
    required this.roomNumber,
    this.status = 'entered_opd',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to JSON to send to MongoDB backend
  Map<String, dynamic> toJson() => {
        'patientName': patientName,
        'patientPhone': patientPhone,
        'doctorName': doctorName,
        'roomNumber': roomNumber,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  // Convert from JSON received from MongoDB backend
  factory WalkInBooking.fromJson(Map<String, dynamic> json) => WalkInBooking(
        id: json['_id'],
        patientName: json['patientName'],
        patientPhone: json['patientPhone'],
        doctorName: json['doctorName'],
        roomNumber: json['roomNumber'],
        status: json['status'] ?? 'waiting',
        createdAt: DateTime.parse(json['createdAt']),
      );
}
