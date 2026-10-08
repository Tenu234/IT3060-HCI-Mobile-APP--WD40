import 'package:flutter/material.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

const _primary = Color(0xFF006D77);

class WalkInBookingScreen extends StatefulWidget {
  const WalkInBookingScreen({super.key});
  @override
  State<WalkInBookingScreen> createState() => _WalkInBookingScreenState();
}

class _WalkInBookingScreenState extends State<WalkInBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _api = StaffApiService();

  String _doctor = 'Dr. Perera';
  String _room = 'Room 1';
  bool _loading = false;

  final _doctors = ['Dr. Perera', 'Dr. Silva', 'Dr. Fernando', 'Dr. Jayasinghe'];
  final _rooms   = ['Room 1', 'Room 2', 'Room 3', 'Room 4'];

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await _api.createBooking(WalkInBooking(
      patientName: _nameCtrl.text.trim(),
      patientPhone: _phoneCtrl.text.trim(),
      doctorName: _doctor,
      roomNumber: _room,
    ));
    setState(() => _loading = false);
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient registered successfully'), backgroundColor: _primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed — check connection'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Walk-In Booking', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Section(label: 'Patient Details', children: [
                _Field(ctrl: _nameCtrl, label: 'Full Name', icon: Icons.person_rounded,
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 14),
                _Field(ctrl: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_rounded,
                    keyboard: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Required' : null),
              ]),
              const SizedBox(height: 20),
              _Section(label: 'Assignment', children: [
                _Dropdown(
                  label: 'Doctor',
                  icon: Icons.medical_services_rounded,
                  value: _doctor,
                  items: _doctors,
                  onChanged: (v) => setState(() => _doctor = v!),
                ),
                const SizedBox(height: 14),
                _Dropdown(
                  label: 'Room',
                  icon: Icons.meeting_room_rounded,
                  value: _room,
                  items: _rooms,
                  onChanged: (v) => setState(() => _room = v!),
                ),
              ]),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Register Patient',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _Section({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType keyboard;
  final String? Function(String?) validator;
  const _Field({required this.ctrl, required this.label, required this.icon,
      this.keyboard = TextInputType.text, required this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE2E6))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE2E6))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final List<String> items;
  final void Function(String?) onChanged;
  const _Dropdown({required this.label, required this.icon, required this.value,
      required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE2E6))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE2E6))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
