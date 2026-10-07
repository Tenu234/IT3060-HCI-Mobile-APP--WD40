import 'package:flutter/material.dart';
import '../../models/doctor_queue_item.dart';
import '../../models/dispatch_alert_model.dart';
import '../../services/doctor_service.dart';
import 'doctor_theme.dart';

class ConsultationNotesAndDispatchScreen extends StatefulWidget {
  final DoctorQueueItem? patientToConsult;

  const ConsultationNotesAndDispatchScreen({super.key, this.patientToConsult});

  @override
  State<ConsultationNotesAndDispatchScreen> createState() =>
      _ConsultationNotesAndDispatchScreenState();
}

class _ConsultationNotesAndDispatchScreenState
    extends State<ConsultationNotesAndDispatchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Consultation Notes Controllers (CRUD 1)
  DoctorQueueItem? _selectedPatient;
  List<DoctorQueueItem> _activePatients = [];
  bool _isLoadingPatients = false;

  final _clinicalNotesController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  bool _isSavingNotes = false;

  // Quick diagnosis chips
  final List<String> _quickDiagnoses = [
    'Viral Pharyngitis',
    'Essential Hypertension',
    'Acute Bronchitis',
    'Gastritis / Acid Reflux',
    'Lumbar Back Strain',
    'Tension Headache',
    'Type 2 Diabetes Review',
  ];

  // Dispatch Alerts State (CRUD 2)
  List<DispatchAlertModel> _alerts = [];
  bool _isLoadingAlerts = false;
  final _tokenAlertController = TextEditingController();
  final _patientNameAlertController = TextEditingController();
  final _customMessageController = TextEditingController();
  String _selectedRoom = 'Consultation Room 2';
  String _selectedPriority = 'normal';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _selectedPatient = widget.patientToConsult;
    if (_selectedPatient != null) {
      _clinicalNotesController.text = _selectedPatient!.clinicalNotes;
      _diagnosisController.text = _selectedPatient!.diagnosis;
      _prescriptionController.text = _selectedPatient!.prescription;
      _tokenAlertController.text = _selectedPatient!.tokenNumber;
      _patientNameAlertController.text = _selectedPatient!.patientName;
    }

    _loadActivePatients();
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clinicalNotesController.dispose();
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _tokenAlertController.dispose();
    _patientNameAlertController.dispose();
    _customMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadActivePatients() async {
    setState(() => _isLoadingPatients = true);
    try {
      final queue = await DoctorService.getDailyQueue(status: 'all');
      if (mounted) {
        setState(() {
          _activePatients = queue.where((p) => p.status != 'cancelled').toList();
          if (_selectedPatient == null && _activePatients.isNotEmpty) {
            _selectPatient(_activePatients.first);
          }
          _isLoadingPatients = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPatients = false);
    }
  }

  void _selectPatient(DoctorQueueItem patient) {
    setState(() {
      _selectedPatient = patient;
      _clinicalNotesController.text = patient.clinicalNotes;
      _diagnosisController.text = patient.diagnosis;
      _prescriptionController.text = patient.prescription;
      _tokenAlertController.text = patient.tokenNumber;
      _patientNameAlertController.text = patient.patientName;
    });
  }

  // CRUD 1 - Save notes
  Future<void> _saveNotes({bool completeTurn = false}) async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient first.')),
      );
      return;
    }

    if (_diagnosisController.text.trim().isEmpty && completeTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Diagnosis before completing the consultation.'),
          backgroundColor: DoctorTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSavingNotes = true);
    try {
      await DoctorService.saveConsultationNotes(
        _selectedPatient!.id,
        clinicalNotes: _clinicalNotesController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
        prescription: _prescriptionController.text.trim(),
        markCompleted: completeTurn,
      );

      if (mounted) {
        setState(() => _isSavingNotes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              completeTurn
                  ? 'Consultation for ${_selectedPatient!.tokenNumber} marked COMPLETED!'
                  : 'Clinical notes saved successfully.',
            ),
            backgroundColor: DoctorTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (completeTurn) {
          Navigator.pop(context);
        } else {
          _loadActivePatients();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingNotes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DoctorTheme.danger),
        );
      }
    }
  }

  // CRUD 2 - Load Alerts
  Future<void> _loadAlerts() async {
    setState(() => _isLoadingAlerts = true);
    try {
      final list = await DoctorService.getDispatchAlerts();
      if (mounted) {
        setState(() {
          _alerts = list;
          _isLoadingAlerts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAlerts = false);
    }
  }

  // CRUD 2 - Dispatch Alert
  Future<void> _dispatchAlert() async {
    final token = _tokenAlertController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or select a Token Number.'),
          backgroundColor: DoctorTheme.warning,
        ),
      );
      return;
    }

    final customMsg = _customMessageController.text.trim();
    final message = customMsg.isNotEmpty
        ? customMsg
        : '$token enter $_selectedRoom';

    try {
      final created = await DoctorService.createDispatchAlert(
        tokenNumber: token,
        patientName: _patientNameAlertController.text.trim(),
        roomNumber: _selectedRoom,
        message: message,
        alertType: 'queue_call',
        priority: _selectedPriority,
      );

      if (mounted) {
        _customMessageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Dispatched: "${created.message}"')),
              ],
            ),
            backgroundColor: DoctorTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadAlerts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DoctorTheme.danger),
        );
      }
    }
  }

  // CRUD 2 - Dismiss Alert
  Future<void> _dismissAlert(DispatchAlertModel alert) async {
    try {
      await DoctorService.deleteDispatchAlert(alert.id);
      if (mounted) {
        setState(() {
          _alerts.removeWhere((a) => a.id == alert.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification dismissed.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DoctorTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorTheme.background,
      appBar: AppBar(
        title: const Text('Consultation & Dispatch Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: DoctorTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: DoctorTheme.primary,
              indicatorWeight: 3,
              labelColor: DoctorTheme.primary,
              unselectedLabelColor: DoctorTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.description_outlined, size: 20), text: 'Clinical Notes & Rx'),
                Tab(icon: Icon(Icons.campaign_outlined, size: 20), text: 'Dispatch Alerts (FR09)'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClinicalNotesTab(),
          _buildDispatchAlertsTab(),
        ],
      ),
    );
  }

  Widget _buildClinicalNotesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Patient Selection Dropdown
        if (_isLoadingPatients)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(color: DoctorTheme.primary),
          )
        else if (_activePatients.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: DoctorTheme.cardDecoration(
              borderColor: DoctorTheme.primary.withValues(alpha: 0.3),
              bgColor: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedPatient?.id,
                hint: const Text('Select Patient to Add Notes'),
                items: _activePatients.map((p) {
                  return DropdownMenuItem<String>(
                    value: p.id,
                    child: Text(
                      '${p.tokenNumber} - ${p.patientName} (${p.status.toUpperCase()})',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: DoctorTheme.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  final p = _activePatients.firstWhere((x) => x.id == val);
                  _selectPatient(p);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Selected Patient Details Banner
        if (_selectedPatient != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: DoctorTheme.cardDecoration(
              borderColor: DoctorTheme.border,
              bgColor: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DoctorTheme.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DoctorTheme.primaryLight.withValues(alpha: 0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedPatient!.tokenNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: DoctorTheme.primaryDark, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPatient!.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: DoctorTheme.textPrimary),
                      ),
                      if (_selectedPatient!.symptoms.isNotEmpty)
                        Text(
                          'Complaint: "${_selectedPatient!.symptoms}"',
                          style: const TextStyle(color: DoctorTheme.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),

        // 1. Diagnosis
        const Text(
          'Diagnosis / Clinical Findings *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: DoctorTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DoctorTheme.border),
          ),
          child: TextField(
            controller: _diagnosisController,
            decoration: const InputDecoration(
              hintText: 'e.g. Acute Viral Pharyngitis, Hypertension...',
              hintStyle: TextStyle(color: DoctorTheme.textMuted, fontSize: 13),
              prefixIcon: Icon(Icons.medical_information_outlined, color: DoctorTheme.primary, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Quick Diagnoses Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickDiagnoses.map((diag) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(diag, style: const TextStyle(fontSize: 11, color: DoctorTheme.textPrimary)),
                  backgroundColor: DoctorTheme.surfaceSubtle,
                  side: const BorderSide(color: DoctorTheme.border),
                  onPressed: () {
                    setState(() => _diagnosisController.text = diag);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Clinical Observations & Notes
        const Text(
          'Clinical Notes / Examination Remarks',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: DoctorTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DoctorTheme.border),
          ),
          child: TextField(
            controller: _clinicalNotesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter clinical observations, vitals, temperature, BP...',
              hintStyle: TextStyle(color: DoctorTheme.textMuted, fontSize: 13),
              prefixIcon: Icon(Icons.notes_rounded, color: DoctorTheme.primary, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Prescription & Medication Instructions
        const Text(
          'Prescription & Medication Instructions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: DoctorTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DoctorTheme.border),
          ),
          child: TextField(
            controller: _prescriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. Tab Paracetamol 500mg TDS x 3 days\nAmoxicillin 500mg TDS x 5 days',
              hintStyle: TextStyle(color: DoctorTheme.textMuted, fontSize: 13),
              prefixIcon: Icon(Icons.medication_outlined, color: DoctorTheme.primary, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: DoctorTheme.primary,
                  side: const BorderSide(color: DoctorTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSavingNotes ? null : () => _saveNotes(completeTurn: false),
                icon: const Icon(Icons.save_outlined, size: 19),
                label: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DoctorTheme.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSavingNotes ? null : () => _saveNotes(completeTurn: true),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
                label: const Text('Save & Complete Turn', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDispatchAlertsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Dispatch Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: DoctorTheme.cardDecoration(
            borderColor: DoctorTheme.primaryLight.withValues(alpha: 0.4),
            bgColor: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.send_time_extension_rounded, color: DoctorTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Trigger Real-Time Queue Alert',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: DoctorTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  // Token Input
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _tokenAlertController,
                      decoration: InputDecoration(
                        labelText: 'Token No.',
                        hintText: 'A-104',
                        filled: true,
                        fillColor: DoctorTheme.surfaceSubtle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: DoctorTheme.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Room Dropdown
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedRoom,
                      decoration: InputDecoration(
                        labelText: 'Destination Room',
                        filled: true,
                        fillColor: DoctorTheme.surfaceSubtle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: DoctorTheme.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Consultation Room 1', child: Text('Room 1')),
                        DropdownMenuItem(value: 'Consultation Room 2', child: Text('Room 2')),
                        DropdownMenuItem(value: 'OPD Lab / Diagnostics', child: Text('Lab')),
                        DropdownMenuItem(value: 'OPD Pharmacy', child: Text('Pharmacy')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRoom = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Custom message
              TextField(
                controller: _customMessageController,
                decoration: InputDecoration(
                  hintText: 'Custom message (e.g., Token A-104 enter Room 2)',
                  filled: true,
                  fillColor: DoctorTheme.surfaceSubtle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: DoctorTheme.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),

              // Priority toggle chips
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Normal Alert'),
                    selected: _selectedPriority == 'normal',
                    selectedColor: DoctorTheme.primaryTint,
                    labelStyle: TextStyle(
                      color: _selectedPriority == 'normal' ? DoctorTheme.primaryDark : DoctorTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (val) => setState(() => _selectedPriority = 'normal'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Urgent Alert'),
                    selected: _selectedPriority == 'urgent',
                    selectedColor: DoctorTheme.dangerLight,
                    labelStyle: TextStyle(
                      color: _selectedPriority == 'urgent' ? DoctorTheme.danger : DoctorTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (val) => setState(() => _selectedPriority = 'urgent'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Full-width Broadcast Call Button (No Overflow!)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DoctorTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _dispatchAlert,
                  icon: const Icon(Icons.campaign_rounded, size: 20),
                  label: const Text('Broadcast Call (Dispatch)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Dispatch Logs Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notification Dispatch Logs (${_alerts.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: DoctorTheme.textPrimary),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: DoctorTheme.primary),
              onPressed: _loadAlerts,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Logs List
        if (_isLoadingAlerts)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: DoctorTheme.primary)))
        else if (_alerts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No alert logs dispatched yet.', style: TextStyle(color: DoctorTheme.textMuted)),
            ),
          )
        else
          ..._alerts.map((alert) => _buildAlertLogItem(alert)),
      ],
    );
  }

  Widget _buildAlertLogItem(DispatchAlertModel alert) {
    final isUrgent = alert.priority == 'urgent';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: DoctorTheme.cardDecoration(
        borderColor: isUrgent ? DoctorTheme.danger.withValues(alpha: 0.3) : DoctorTheme.border,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isUrgent ? DoctorTheme.dangerLight : DoctorTheme.primaryTint,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            isUrgent ? Icons.priority_high_rounded : Icons.notifications_active_outlined,
            color: isUrgent ? DoctorTheme.danger : DoctorTheme.primary,
            size: 19,
          ),
        ),
        title: Text(
          alert.message,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: DoctorTheme.textPrimary),
        ),
        subtitle: Text(
          'Token: ${alert.tokenNumber} • ${_formatTime(alert.createdAt)}',
          style: const TextStyle(fontSize: 11, color: DoctorTheme.textMuted),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: DoctorTheme.textMuted, size: 20),
          tooltip: 'Dismiss / Clear Alert',
          onPressed: () => _dismissAlert(alert),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }
}
