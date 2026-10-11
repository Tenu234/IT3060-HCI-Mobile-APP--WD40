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
  int _step = 0; // 0: Select Doctor, 1: Date & Slot, 2: Review
  bool _isLoading = false;

  // Step 1
  String? _selectedDoctor;

  // Step 2
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

  final List<String> _steps = ['Select Doctor', 'Select Date & Slot', 'Review & Confirm'];

  bool get _canProceed {
    if (_step == 0) return _selectedDoctor != null;
    if (_step == 1) return _selectedDate != null && _selectedSlot != null;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final active = i == _step;
          final done = i < _step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: done || active
                            ? const Color(0xFF00897B)
                            : Colors.grey.shade300,
                        child: done
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    color: active ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                      ),
                      const SizedBox(height: 4),
                      Text(_steps[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              color: active
                                  ? const Color(0xFF00897B)
                                  : Colors.grey)),
                    ],
                  ),
                ),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: i < _step
                          ? const Color(0xFF00897B)
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Step 1: Select Doctor ─────────────────────────────────────────────────
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              children: [
                TextSpan(text: 'Select Doctor '),
                TextSpan(text: '*', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedDoctor,
            hint: const Text('Select a doctor'),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _doctors.map((d) => DropdownMenuItem(
              value: d['value'],
              child: Text(d['label']!, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) => setState(() => _selectedDoctor = v),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Calendar + Slots ──────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Date',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          _buildCalendar(),
          const SizedBox(height: 20),
          if (_selectedDate != null) ...[
            Text('Available Slots ($_formattedDate)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            _buildSlotGrid(),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 0=Sun
    const months = ['January','February','March','April','May','June',
                    'July','August','September','October','November','December'];
    const days = ['Su','Mo','Tu','We','Th','Fr','Sa'];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Month header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() =>
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                ),
                Text('${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() =>
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                ),
              ],
            ),
          ),

          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((d) => SizedBox(
                width: 36,
                child: Text(d,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Date grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
              itemCount: startWeekday + lastDay.day,
              itemBuilder: (_, i) {
                if (i < startWeekday) return const SizedBox();
                final day = i - startWeekday + 1;
                final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                final isSelected = _selectedDate?.day == day &&
                    _selectedDate?.month == _focusedMonth.month &&
                    _selectedDate?.year == _focusedMonth.year;
                final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

                return GestureDetector(
                  onTap: isPast ? null : () => setState(() {
                    _selectedDate = date;
                    _selectedSlot = null;
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFF00897B)
                          : Colors.transparent,
                      border: isToday && !isSelected
                          ? Border.all(color: const Color(0xFF00897B), width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text('$day',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : isPast
                                      ? Colors.grey.shade300
                                      : Colors.black87)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSlotGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _timeSlots.map((slot) {
        final isFull = _fullSlots.contains(slot);
        final isSelected = _selectedSlot == slot;
        return GestureDetector(
          onTap: isFull ? null : () => setState(() => _selectedSlot = slot),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00897B)
                  : isFull
                      ? Colors.grey.shade100
                      : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00897B)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              isFull ? '$slot (Full)' : slot,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isFull
                        ? Colors.grey
                        : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Step 3: Review ────────────────────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _summaryRow('Hospital', widget.hospitalName),
          _summaryRow('OPD', widget.opdName),
          _summaryRow('Doctor', _selectedDoctor ?? ''),
          _summaryRow('Date', _formattedDate),
          _summaryRow('Time', _selectedSlot ?? ''),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF00897B), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please arrive 15 minutes before your appointment time.',
                    style: TextStyle(color: Color(0xFF00695C), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
                width: 80,
                child: Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 13))),
            const SizedBox(width: 12),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_step == 1 ? 'Select Date & Time' : 'Book Appointment'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _stepIndicator(),
          const Divider(height: 1),
          Expanded(
            child: _step == 0
                ? _buildStep1()
                : _step == 1
                    ? _buildStep2()
                    : _buildStep3(),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceed
                        ? () {
                            if (_step < 2) {
                              setState(() => _step++);
                            } else {
                              _confirm();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _step == 0
                                    ? 'Continue to Date & Slot'
                                    : _step == 1
                                        ? 'Review Appointment'
                                        : 'Confirm & Book Appointment',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, size: 18),
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
