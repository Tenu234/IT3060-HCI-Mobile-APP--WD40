import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

class WalkInBookingScreen extends StatefulWidget {
  const WalkInBookingScreen({super.key});
  @override
  State<WalkInBookingScreen> createState() => _WalkInBookingScreenState();
}

class _WalkInBookingScreenState extends State<WalkInBookingScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _api        = StaffApiService();

  String _doctor    = 'Dr. Perera';
  String _room      = 'Room 1';
  String _department = 'General Medicine';
  bool   _loading   = false;

  final _doctors     = ['Dr. Perera', 'Dr. Silva', 'Dr. Fernando', 'Dr. Jayasinghe'];
  final _rooms       = ['Room 1', 'Room 2', 'Room 3', 'Room 4'];
  final _departments = ['General Medicine', 'Cardiology', 'Neurology', 'Orthopaedics', 'Paediatrics'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await _api.createBooking(WalkInBooking(
      patientName:  _nameCtrl.text.trim(),
      patientPhone: _phoneCtrl.text.trim(),
      doctorName:   _doctor,
      roomNumber:   _room,
    ));

    setState(() => _loading = false);
    if (!mounted) return;

    if (result != null) {
      // Show token dialog
      await _showTokenDialog(result);
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed — check connection'),
        backgroundColor: kCancelled,
      ));
    }
  }

  Future<void> _showTokenDialog(WalkInBooking booking) async {
    // Generate token from ID tail or fallback to timestamp
    final raw  = booking.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final token = 'Q-${raw.substring(raw.length > 4 ? raw.length - 4 : 0).toUpperCase()}';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: kDone.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: kDone, size: 34),
              ),
              const SizedBox(height: 16),
              const Text('Patient Registered!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kText)),
              const SizedBox(height: 6),
              Text(booking.patientName,
                  style: const TextStyle(fontSize: 14, color: kTextMuted)),

              const SizedBox(height: 24),

              // Token box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimary.withOpacity(0.2)),
                ),
                child: Column(children: [
                  const Text('QUEUE TOKEN',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(token,
                      style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                          letterSpacing: 2)),
                ]),
              ),

              const SizedBox(height: 16),

              // Details
              _TokenRow(icon: Icons.medical_services_rounded,
                  label: 'Doctor', value: booking.doctorName),
              const SizedBox(height: 6),
              _TokenRow(icon: Icons.meeting_room_rounded,
                  label: 'Room', value: booking.roomNumber),
              const SizedBox(height: 6),
              _TokenRow(icon: Icons.local_hospital_rounded,
                  label: 'Department', value: _department),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('New Walk-In Booking',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Patient details ──────────────────────────────────────────
              _SectionHeader(label: 'Patient Details',
                  icon: Icons.person_rounded),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: kCardDecoration(),
                child: Column(children: [
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: kInputDecoration(
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: kInputDecoration(
                        label: 'Phone Number',
                        icon: Icons.phone_outlined),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ]),
              ),

              const SizedBox(height: 22),

              // ── Assignment ───────────────────────────────────────────────
              _SectionHeader(label: 'Assignment',
                  icon: Icons.assignment_ind_rounded),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: kCardDecoration(),
                child: Column(children: [
                  _StyledDropdown(
                    label: 'Department',
                    icon: Icons.local_hospital_outlined,
                    value: _department,
                    items: _departments,
                    onChanged: (v) => setState(() => _department = v!),
                  ),
                  const SizedBox(height: 14),
                  _StyledDropdown(
                    label: 'Doctor',
                    icon: Icons.medical_services_outlined,
                    value: _doctor,
                    items: _doctors,
                    onChanged: (v) => setState(() => _doctor = v!),
                  ),
                  const SizedBox(height: 14),
                  _StyledDropdown(
                    label: 'Room',
                    icon: Icons.meeting_room_outlined,
                    value: _room,
                    items: _rooms,
                    onChanged: (v) => setState(() => _room = v!),
                  ),
                ]),
              ),

              const SizedBox(height: 32),

              // ── Submit ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.how_to_reg_rounded, size: 20),
                  label: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Generate Ticket & Book',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _submit,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: kPrimary, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kText)),
      ]);
}

class _StyledDropdown extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final List<String> items;
  final void Function(String?) onChanged;
  const _StyledDropdown(
      {required this.label,
      required this.icon,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: kInputDecoration(label: label, icon: icon),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      dropdownColor: Colors.white,
    );
  }
}

class _TokenRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _TokenRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: kPrimary, size: 16),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: kTextMuted)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kText)),
        ),
      ]);
}
