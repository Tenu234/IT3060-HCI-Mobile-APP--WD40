class DoctorQueueItem {
  final String id;
  final String tokenNumber;
  final String patientName;
  final String? patientPhone;
  final String? patientNic;
  final String hospitalName;
  final String opdName;
  final String doctorName;
  final String roomNumber;
  final String date;
  final String timeSlot;
  final String symptoms;
  final String status; // waiting, in_consultation, completed, skipped
  final String clinicalNotes;
  final String diagnosis;
  final String prescription;
  final DateTime? consultationStartTime;
  final DateTime? consultationEndTime;

  DoctorQueueItem({
    required this.id,
    required this.tokenNumber,
    required this.patientName,
    this.patientPhone,
    this.patientNic,
    required this.hospitalName,
    required this.opdName,
    required this.doctorName,
    required this.roomNumber,
    required this.date,
    required this.timeSlot,
    required this.symptoms,
    required this.status,
    required this.clinicalNotes,
    required this.diagnosis,
    required this.prescription,
    this.consultationStartTime,
    this.consultationEndTime,
  });

  factory DoctorQueueItem.fromJson(Map<String, dynamic> json) {
    String pName = json['patientName'] ?? '';
    String? pPhone;
    String? pNic;

    if (json['patientId'] is Map<String, dynamic>) {
      final pMap = json['patientId'] as Map<String, dynamic>;
      if (pName.isEmpty) pName = pMap['name'] ?? 'Patient';
      pPhone = pMap['phone'];
      pNic = pMap['nic'];
    }

    if (pName.isEmpty) pName = 'Patient';

    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    return DoctorQueueItem(
      id: json['_id'] ?? json['id'] ?? '',
      tokenNumber: json['tokenNumber'] ?? 'A-100',
      patientName: pName,
      patientPhone: pPhone,
      patientNic: pNic,
      hospitalName: json['hospitalName'] ?? 'National Hospital',
      opdName: json['opdName'] ?? 'General OPD',
      doctorName: json['doctorName'] ?? 'Dr. RKAM Deshan',
      roomNumber: json['roomNumber'] ?? 'Consultation Room 2',
      date: json['date'] ?? '',
      timeSlot: json['timeSlot'] ?? '',
      symptoms: json['symptoms'] ?? '',
      status: json['status'] ?? 'waiting',
      clinicalNotes: json['clinicalNotes'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      prescription: json['prescription'] ?? '',
      consultationStartTime: parseDate(json['consultationStartTime']),
      consultationEndTime: parseDate(json['consultationEndTime']),
    );
  }
}
