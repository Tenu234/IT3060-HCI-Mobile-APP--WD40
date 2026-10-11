import 'package:flutter/material.dart';
import '../../models/doctor_summary_model.dart';
import '../../models/doctor_queue_item.dart';
import '../../services/doctor_service.dart';
import 'doctor_theme.dart';

class DoctorReportsScreen extends StatefulWidget {
  const DoctorReportsScreen({super.key});

  @override
  State<DoctorReportsScreen> createState() => _DoctorReportsScreenState();
}

class _DoctorReportsScreenState extends State<DoctorReportsScreen> {
  DoctorSummaryModel? _summary;
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    try {
      final data = await DoctorService.getDoctorSummary();
      if (mounted) {
        setState(() {
          _summary = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: DoctorTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCompletedDetailsModal(DoctorQueueItem patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: DoctorTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: DoctorTheme.successLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DoctorTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    patient.tokenNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: DoctorTheme.success),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: DoctorTheme.textPrimary),
                      ),
                      Text('Consultation Date: ${patient.date}', style: const TextStyle(color: DoctorTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: DoctorTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 24, color: DoctorTheme.border),

            _buildDetailRow('Diagnosis:', patient.diagnosis.isEmpty ? 'Not specified' : patient.diagnosis, isBold: true),
            const SizedBox(height: 12),
            _buildDetailRow('Clinical Notes:', patient.clinicalNotes.isEmpty ? 'No notes entered' : patient.clinicalNotes),
            const SizedBox(height: 12),
            _buildDetailRow('Prescription & Advice:', patient.prescription.isEmpty ? 'No prescription recorded' : patient.prescription),
            const SizedBox(height: 12),
            if (patient.symptoms.isNotEmpty)
              _buildDetailRow('Initial Symptoms / Chief Complaint:', patient.symptoms),

            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DoctorTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close Record', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String content, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: DoctorTheme.primary)),
        const SizedBox(height: 3),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: DoctorTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: DoctorTheme.primary));
    }

    final completedList = _summary?.completedList ?? [];
    final filteredCompleted = completedList.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.tokenNumber.toLowerCase().contains(q) ||
          p.patientName.toLowerCase().contains(q) ||
          p.diagnosis.toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      color: DoctorTheme.primary,
      onRefresh: _loadSummary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Title
          const Text(
            'Doctor Daily Performance & Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DoctorTheme.textPrimary),
          ),
          const SizedBox(height: 14),

          // 4 Metric KPI Cards (Total, Completed, Waiting, Skipped)
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Total Patients',
                  '${_summary?.totalPatients ?? 0}',
                  Icons.groups_outlined,
                  DoctorTheme.primary,
                  DoctorTheme.primaryTint,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  'Completed (FR15)',
                  '${_summary?.completedCount ?? 0}',
                  Icons.check_circle_outline_rounded,
                  DoctorTheme.success,
                  DoctorTheme.successLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'In Queue / Waiting',
                  '${_summary?.waitingCount ?? 0}',
                  Icons.hourglass_top_rounded,
                  DoctorTheme.warning,
                  DoctorTheme.warningLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  'Skipped / Absent',
                  '${_summary?.skippedCount ?? 0}',
                  Icons.person_off_outlined,
                  DoctorTheme.danger,
                  DoctorTheme.dangerLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Completed Logs Header & Search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completed Logs (${filteredCompleted.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DoctorTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DoctorTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FR15 Audit',
                  style: TextStyle(fontSize: 11, color: DoctorTheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DoctorTheme.border),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Filter completed by token, name or diagnosis...',
                hintStyle: const TextStyle(color: DoctorTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: DoctorTheme.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: DoctorTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 12),

          // Completed Items List
          if (filteredCompleted.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No completed patient logs match your query.',
                  style: TextStyle(color: DoctorTheme.textMuted),
                ),
              ),
            )
          else
            ...filteredCompleted.map((item) => _buildCompletedCard(item)),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, Color bgTint) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DoctorTheme.cardDecoration(
        borderColor: color.withValues(alpha: 0.25),
        bgColor: bgTint,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: DoctorTheme.textSecondary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(DoctorQueueItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: DoctorTheme.cardDecoration(
        borderColor: DoctorTheme.border,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: DoctorTheme.successLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DoctorTheme.success.withValues(alpha: 0.3)),
          ),
          child: Text(
            item.tokenNumber,
            style: const TextStyle(color: DoctorTheme.success, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        title: Text(
          item.patientName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: DoctorTheme.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              item.diagnosis.isNotEmpty ? 'Rx: ${item.diagnosis}' : 'Consultation completed',
              style: const TextStyle(color: DoctorTheme.textSecondary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.prescription.isNotEmpty)
              Text(
                'Meds: ${item.prescription}',
                style: const TextStyle(color: DoctorTheme.textMuted, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: DoctorTheme.textMuted),
        onTap: () => _showCompletedDetailsModal(item),
      ),
    );
  }
}
