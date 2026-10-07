import 'package:flutter/material.dart';
import '../../models/doctor_queue_item.dart';
import '../../models/dispatch_alert_model.dart';
import '../../services/doctor_service.dart';

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

  // Consultation Notes Controllers (CRUD 1: Create / Update notes)
  DoctorQueueItem? _selectedPatient;
  List<DoctorQueueItem> _activePatients = [];
  bool _isLoadingPatients = false;

  final _clinicalNotesController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  bool _isSavingNotes = false;

  // Common quick diagnoses for easy 1-tap entry (HCI usability heuristic)
  final List<String> _quickDiagnoses = [
    'Viral Pharyngitis',
    'Essential Hypertension',
    'Acute Bronchitis',
    'Gastritis / Acid Reflux',
    'Lumbar Strain / Backache',
    'Tension Headache',
    'Type 2 Diabetes Review',
  ];

  // Dispatch Alerts State (CRUD 2: Notification & Alert Dispatch)
  List<DispatchAlertModel> _alerts = [];
  bool _isLoadingAlerts = false;
  final _tokenAlertController = TextEditingController();
  final _patientNameAlertController = TextEditingController();
  final _customMessageController = TextEditingController();
  String _selectedRoom = 'Consultation Room 2';
  String _selectedAlertType = 'queue_call'; // queue_call, lab_dispatch, pharmacy, urgent_call
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

  // CRUD 1 - CREATE / UPDATE: Save clinical notes and diagnosis
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
          backgroundColor: Colors.orange,
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
            backgroundColor: Colors.green,
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // CRUD 2 - READ: Load Notification & Alert Dispatch Logs
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

  // CRUD 2 - CREATE: Trigger real-time queue call notifications ("Token A-104 enter Consultation Room 2")
  Future<void> _dispatchAlert() async {
    final token = _tokenAlertController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a Token Number.')),
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
        alertType: _selectedAlertType,
        priority: _selectedPriority,
      );

      if (mounted) {
        _customMessageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📢 Alert Dispatched: "${created.message}"'),
            backgroundColor: Colors.teal,
          ),
        );
        _loadAlerts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // CRUD 2 - DELETE: Clear or dismiss sent notification item
  Future<void> _dismissAlert(DispatchAlertModel alert) async {
    try {
      await DoctorService.deleteDispatchAlert(alert.id);
      if (mounted) {
        setState(() {
          _alerts.removeWhere((a) => a.id == alert.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispatch notification dismissed.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation & Dispatch Alerts'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'Clinical Notes & Rx'),
            Tab(icon: Icon(Icons.campaign), text: 'Dispatch Alerts (FR09)'),
          ],
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

  // TAB 1: Clinical Notes, Diagnosis remarks, Prescription details
  Widget _buildClinicalNotesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Patient Selection Dropdown / Selector
        if (_isLoadingPatients)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          )
        else if (_activePatients.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
          const SizedBox(height: 16),
        ],

        // Selected Patient Mini Banner
        if (_selectedPatient != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  child: Text(_selectedPatient!.tokenNumber.replaceFirst('A-', '')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPatient!.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (_selectedPatient!.symptoms.isNotEmpty)
                        Text(
                          'Chief complaint: "${_selectedPatient!.symptoms}"',
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // 1. Diagnosis Field
        const Text(
          'Diagnosis / Clinical Findings *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _diagnosisController,
          decoration: InputDecoration(
            hintText: 'e.g. Acute Viral Pharyngitis, Hypertension...',
            prefixIcon: const Icon(Icons.medical_information, color: Colors.teal),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),

        // Quick Diagnoses Chips (HCI usability heuristic: Recognition over Recall)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickDiagnoses.map((diag) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(diag, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.teal.shade50,
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _clinicalNotesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter clinical observations, vitals, temperature, BP...',
            prefixIcon: const Icon(Icons.notes, color: Colors.teal),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // 3. Prescription & Dosage Details
        const Text(
          'Prescription & Medication Instructions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _prescriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Tab Paracetamol 500mg TDS x 3 days\nAmoxicillin 500mg TDS x 5 days',
            prefixIcon: const Icon(Icons.medication, color: Colors.teal),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons (Save vs Complete)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSavingNotes ? null : () => _saveNotes(completeTurn: false),
                icon: const Icon(Icons.save),
                label: const Text('Save Notes Draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSavingNotes ? null : () => _saveNotes(completeTurn: true),
                icon: const Icon(Icons.check_circle),
                label: const Text('Save & Complete Turn'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // TAB 2: Notification & Alert Dispatch (FR09-FR10 CRUD)
  Widget _buildDispatchAlertsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick Call & Dispatcher Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.send_time_extension, color: Colors.teal),
                  const SizedBox(width: 8),
                  const Text(
                    'Trigger Real-Time Queue Alert',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Room Dropdown
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedRoom,
                      decoration: InputDecoration(
                        labelText: 'Destination Room',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

              // Custom message (optional)
              TextField(
                controller: _customMessageController,
                decoration: InputDecoration(
                  hintText: 'Custom message (e.g., Token A-104 enter Consultation Room 2)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),

              // Priority toggle & Dispatch Button
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Normal Alert'),
                    selected: _selectedPriority == 'normal',
                    selectedColor: Colors.teal.shade100,
                    onSelected: (val) => setState(() => _selectedPriority = 'normal'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Urgent Alert'),
                    selected: _selectedPriority == 'urgent',
                    selectedColor: Colors.red.shade100,
                    labelStyle: TextStyle(
                      color: _selectedPriority == 'urgent' ? Colors.red.shade900 : Colors.black87,
                    ),
                    onSelected: (val) => setState(() => _selectedPriority = 'urgent'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _dispatchAlert,
                    icon: const Icon(Icons.campaign, size: 20),
                    label: const Text('Broadcast Call'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Dispatch Logs Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notification Dispatch Logs (${_alerts.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadAlerts,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Logs List (CRUD 2: READ & DELETE)
        if (_isLoadingAlerts)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_alerts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No alert logs dispatched yet.', style: TextStyle(color: Colors.grey[600])),
            ),
          )
        else
          ..._alerts.map((alert) => _buildAlertLogItem(alert)),
      ],
    );
  }

  Widget _buildAlertLogItem(DispatchAlertModel alert) {
    final isUrgent = alert.priority == 'urgent';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUrgent ? Colors.red.shade200 : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUrgent ? Colors.red.shade100 : Colors.teal.shade50,
          child: Icon(
            isUrgent ? Icons.priority_high : Icons.notifications_active,
            color: isUrgent ? Colors.red.shade800 : Colors.teal,
            size: 20,
          ),
        ),
        title: Text(
          alert.message,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'Token: ${alert.tokenNumber} • ${_formatTime(alert.createdAt)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        // CRUD 2 - DELETE: Dismiss or delete sent alert item
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
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
