import 'doctor_queue_item.dart';

class DoctorSummaryModel {
  final int totalPatients;
  final int waitingCount;
  final int inConsultationCount;
  final int completedCount;
  final int skippedCount;
  final List<DoctorQueueItem> completedList;
  final DoctorQueueItem? currentActive;

  DoctorSummaryModel({
    required this.totalPatients,
    required this.waitingCount,
    required this.inConsultationCount,
    required this.completedCount,
    required this.skippedCount,
    required this.completedList,
    this.currentActive,
  });

  factory DoctorSummaryModel.fromJson(Map<String, dynamic> json) {
    final list = (json['completedList'] as List? ?? [])
        .map((e) => DoctorQueueItem.fromJson(e))
        .toList();

    DoctorQueueItem? active;
    if (json['currentActive'] != null) {
      active = DoctorQueueItem.fromJson(json['currentActive']);
    }

    return DoctorSummaryModel(
      totalPatients: json['totalPatients'] ?? 0,
      waitingCount: json['waitingCount'] ?? 0,
      inConsultationCount: json['inConsultationCount'] ?? 0,
      completedCount: json['completedCount'] ?? 0,
      skippedCount: json['skippedCount'] ?? 0,
      completedList: list,
      currentActive: active,
    );
  }
}
