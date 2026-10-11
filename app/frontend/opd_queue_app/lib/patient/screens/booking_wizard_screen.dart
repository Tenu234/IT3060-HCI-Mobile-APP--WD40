import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import 'booking_confirmation_screen.dart';

class BookingWizardScreen extends StatefulWidget {
  final UserModel user;
  final String hospitalName;
  final String opdName;

  const BookingWizardScreen({
    super.key,
    required this.user,
    required this.hospitalName,
    required this.opdName,
  });

  @override
  State<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends State<BookingWizardScreen> {
  int _step = 0; // 0: Doctor + Date + Slot, 1: Review
  bool _isLoading = false;

  // Selections
  String? _selectedDoctor;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedSlot;

  final List<Map<String, String>> _doctors = [
    {'value': 'Dr. A. B. Perera', 'label': 'Dr. A. B. Perera - Consultant Physician'},
    {'value': 'Dr. Fernando',     'label': 'Dr. Fernando - General Physician'},
    {'value': 'Dr. Jayasinghe',   'label': 'Dr. Jayasinghe - Specialist'},
  ];

  final List<String> _timeSlots = [
    '10:30 AM', '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM', '1:00 PM'
  ];

  // Simulate full slots
  final List<String> _fullSlots = ['11:30 AM'];

  final List<String> _steps = ['Select Date & Time', 'Review & Confirm'];

  bool get _canProceed {
    if (_step == 0) return _selectedDoctor != null && _selectedDate != null && _selectedSlot != null;
    return true;
  }

  String get _formattedDate {
    if (_selectedDate == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[_selectedDate!.month - 1]} ${_selectedDate!.day}, ${_selectedDate!.year}';
  }

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    final appointmentId = 'A-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final queueNumber = 10 + (DateTime.now().millisecondsSinceEpoch % 40).toInt();

    await AppointmentService.bookAppointment(
      AppointmentModel(
        id: appointmentId,
        hospitalName: widget.hospitalName,
        opdName: widget.opdName,
        doctorName: _selectedDoctor!,
        date: _selectedDate == null ? '' :
            '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2,'0')}-${_selectedDate!.day.toString().padLeft(2,'0')}',
        timeSlot: _selectedSlot!,
        status: 'upcoming',
      ),
    );
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          user: widget.user,
          hospitalName: widget.hospitalName,
          opdName: widget.opdName,
          doctorName: _selectedDoctor!,
          date: _formattedDate,
          timeSlot: _selectedSlot!,
          appointmentId: appointmentId,
          queueNumber: queueNumber,
        ),
      ));
    }
  }

  // ─── Step indicator ────────────────────────────────────────────────────────
  Widget _stepIndicator() {
    final visualSteps = [
      'Select Doctor',
      'Select Date & Slot',
      'Review & Confirm'
    ];
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: List.generate(visualSteps.length, (i) {
          final done =
              (_step == 0 && i == 0) ? false : i < (_step == 0 ? 0 : 2);
          final active = (_step == 0 && i < 2) || (_step == 1 && i == 2);
          final isDone = _step == 1 && i < 2;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: isDone || (_step == 0 && i == 0)
                            ? const Color(0xFF0D9488)
                            : active
                                ? const Color(0xFF0D9488)
                                : Colors.grey.shade200,
                        child: isDone
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    color: active || (_step == 0 && i == 0)
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                      ),
                      const SizedBox(height: 5),
                      Text(visualSteps[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: active || isDone
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: active || isDone || (_step == 0 && i == 0)
                                  ? const Color(0xFF0D9488)
                                  : Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (i < visualSteps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: isDone
                          ? const Color(0xFF0D9488)
                          : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Step 1: Doctor + Date + Slot (combined) ──────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE), // Soft sky blue
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_rounded,
                    color: Color(0xFF0284C7), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.hospitalName} • ${widget.opdName}',
                    style: const TextStyle(
                      color: Color(0xFF0369A1),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main booking card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor dropdown
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1E293B)),
                    children: [
                      TextSpan(text: 'Select Doctor '),
                      TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDoctor,
                  hint: const Text('Choose a doctor'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_pin_rounded,
                        color: Color(0xFF1A5C6B), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF1A5C6B), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                  ),
                  items: _doctors
                      .map((d) => DropdownMenuItem(
                            value: d['value'],
                            child:
                                Text(d['label']!, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDoctor = v),
                ),
                const SizedBox(height: 22),

                // Date picker
                const Text(
                  'Select Consultation Date',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF1A5C6B),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _selectedSlot = null;
                        _focusedMonth = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedDate == null
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedDate == null
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF0D9488),
                        width: _selectedDate == null ? 1 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: _selectedDate == null
                              ? Colors.grey.shade600
                              : const Color(0xFF0D9488),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Tap to choose appointment date'
                              : _formattedDate,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedDate == null
                                ? FontWeight.normal
                                : FontWeight.bold,
                            color: _selectedDate == null
                                ? Colors.grey.shade600
                                : const Color(0xFF0F766E),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_drop_down,
                          color: _selectedDate == null
                              ? Colors.grey.shade600
                              : const Color(0xFF0D9488),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Slots
                if (_selectedDate != null) ...[
                  Row(
                    children: [
                      const Text(
                        'Available Time Slots',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($_formattedDate)',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF0D9488)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSlotGrid(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: _timeSlots.map((slot) {
        final isFull = _fullSlots.contains(slot);
        final isSelected = _selectedSlot == slot;
        return GestureDetector(
          onTap: isFull ? null : () => setState(() => _selectedSlot = slot),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1A5C6B)
                  : isFull
                      ? const Color(0xFFF1F5F9)
                      : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1A5C6B)
                    : isFull
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1A5C6B).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                ],
                Text(
                  isFull ? '$slot (Full)' : slot,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : isFull
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Step 3: Review ────────────────────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fact_check_rounded,
                          color: Color(0xFF00796B), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Summary',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B)),
                        ),
                        Text(
                          'Please verify your appointment details',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                _summaryRow('Hospital', widget.hospitalName,
                    Icons.local_hospital_rounded),
                _summaryRow(
                    'OPD Clinic', widget.opdName, Icons.medical_services_rounded),
                _summaryRow('Consultant', _selectedDoctor ?? '',
                    Icons.person_pin_rounded),
                _summaryRow('Date', _formattedDate, Icons.calendar_today_rounded),
                _summaryRow(
                    'Time Slot', _selectedSlot ?? '', Icons.schedule_rounded),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_rounded, color: Color(0xFF0D9488), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Please arrive 15 minutes before your time slot to complete initial token verification.',
                    style: TextStyle(
                      color: Color(0xFF0F766E),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0D9488)),
            const SizedBox(width: 10),
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    fontSize: 13),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // User friendly background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5C6B), // Rich medical teal
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _step == 0 ? 'Select Date & Time' : 'Review & Confirm',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _stepIndicator(),
          Expanded(
            child: _step == 0 ? _buildStep1() : _buildStep3(),
          ),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Back',
                          style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceed
                        ? () {
                            if (_step < 1) {
                              setState(() => _step++);
                            } else {
                              _confirm();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A5C6B),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size(0, 50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _step == 0
                                    ? 'Review Appointment'
                                    : 'Confirm & Book Appointment',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
