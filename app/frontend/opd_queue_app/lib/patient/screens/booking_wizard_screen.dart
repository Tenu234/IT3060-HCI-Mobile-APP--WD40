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
  int _step = 0;

  // Step 1 selections
  String? _selectedDoctor;
  // Step 2 selections
  String? _selectedDate;
  String? _selectedSlot;

  bool _isLoading = false;

  final List<String> _doctors = ['Dr. Perera', 'Dr. Fernando', 'Dr. Jayasinghe'];
  final List<String> _timeSlots = ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM'];

  final List<String> _steps = ['Select Doctor', 'Select Date & Slot', 'Review & Confirm'];

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
        date: _selectedDate!,
        timeSlot: _selectedSlot!,
        status: 'upcoming',
      ),
    );
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            user: widget.user,
            hospitalName: widget.hospitalName,
            opdName: widget.opdName,
            doctorName: _selectedDoctor!,
            date: _selectedDate!,
            timeSlot: _selectedSlot!,
            appointmentId: appointmentId,
            queueNumber: queueNumber,
          ),
        ),
      );
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Doctors for ${widget.opdName}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ..._doctors.map((doc) => RadioListTile<String>(
              title: Text(doc),
              value: doc,
              groupValue: _selectedDoctor,
              onChanged: (v) => setState(() => _selectedDoctor = v),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Date', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        // Simple date picker button
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(_selectedDate ?? 'Pick a date'),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 60)),
            );
            if (picked != null) {
              setState(() => _selectedDate =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
            }
          },
        ),
        const SizedBox(height: 20),
        const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _timeSlots.map((slot) {
            final selected = _selectedSlot == slot;
            return ChoiceChip(
              label: Text(slot),
              selected: selected,
              onSelected: (_) => setState(() => _selectedSlot = slot),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Booking Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _summaryRow('Hospital', widget.hospitalName),
        _summaryRow('OPD', widget.opdName),
        _summaryRow('Doctor', _selectedDoctor ?? ''),
        _summaryRow('Date', _selectedDate ?? ''),
        _summaryRow('Time', _selectedSlot ?? ''),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.teal, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please arrive 15 minutes before your appointment time.',
                  style: TextStyle(color: Colors.teal),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  bool get _canProceed {
    if (_step == 0) return _selectedDoctor != null;
    if (_step == 1) return _selectedDate != null && _selectedSlot != null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade300,
                              child: done
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : Text('${i + 1}',
                                      style: TextStyle(
                                          color: active ? Colors.white : Colors.grey,
                                          fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 4),
                            Text(_steps[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: active ? theme.colorScheme.primary : Colors.grey)),
                          ],
                        ),
                      ),
                      if (i < _steps.length - 1)
                        Expanded(
                          child: Divider(
                            color: i < _step ? theme.colorScheme.primary : Colors.grey.shade300,
                            thickness: 2,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _step == 0
                  ? _buildStep1()
                  : _step == 1
                      ? _buildStep2()
                      : _buildStep3(),
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
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
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_step == 2 ? 'Confirm Booking' : 'Next'),
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
