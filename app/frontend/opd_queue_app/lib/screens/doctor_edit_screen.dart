import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';

const kSpecialties = [
  'General Medicine', 'Pediatrics', 'Dentistry', 'Ophthalmology', 'Cardiology', 'Neurology', 'Orthopedics',
  'Dermatology', 'ENT', 'Gynecology', 'Psychiatry', 'Surgery', 'Radiology',
];

/// Add / Edit a doctor. Pass [doctor] to edit.
class DoctorEditScreen extends StatefulWidget {
  final Map<String, dynamic>? doctor;
  const DoctorEditScreen({super.key, this.doctor});
  @override
  State<DoctorEditScreen> createState() => _DoctorEditScreenState();
}

class _DoctorEditScreenState extends State<DoctorEditScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String? _specialty;
  String _status = 'Active';
  bool _saving = false;
  String? _error;
  Map<String, String> _err = {};

  bool get _isEdit => widget.doctor != null;

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;
    if (d != null) {
      _name.text = '${d['name']}';
      _phone.text = '${d['phone'] ?? ''}';
      _email.text = '${d['email'] ?? ''}';
      _specialty = '${d['specialty']}';
      _status = d['status'] == 'on_leave' ? 'On leave' : 'Active';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final e = <String, String>{};
    if (_name.text.trim().length < 3) e['name'] = 'Enter the doctor\'s full name.';
    if (_specialty == null) e['specialty'] = 'Select a specialty.';
    if (_phone.text.trim().isNotEmpty && !RegExp(r'^\+?\d[\d\s-]{6,14}$').hasMatch(_phone.text.trim())) {
      e['phone'] = 'Enter a valid phone number.';
    }
    if (_email.text.trim().isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim())) {
      e['email'] = 'Enter a valid email address.';
    }
    if (e.isNotEmpty) {
      setState(() {
        _err = e;
        _error = 'Please fix the highlighted fields.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _err = {};
    });
    final body = {
      'name': _name.text.trim(),
      'specialty': _specialty,
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'status': _status == 'On leave' ? 'on_leave' : 'active',
    };
    try {
      if (_isEdit) {
        await Api.i.put('/admin/doctors/${widget.doctor!['id']}', body);
      } else {
        await Api.i.post('/admin/doctors', body);
      }
      if (!mounted) return;
      snack(context, _isEdit ? 'Doctor updated' : 'Doctor added');
      Navigator.of(context).pop(true);
    } on ApiException catch (ex) {
      if (mounted) {
        setState(() {
          _error = ex.message;
          _err = ex.fields;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEdit ? 'Edit Doctor' : 'Add Doctor', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const Text('OPD Admin', style: TextStyle(fontSize: 12, color: C.muted)),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LabeledField(label: 'Full Name', controller: _name, hint: 'e.g. Dr. Nadeesha Fernando', error: _err['name']),
            const SizedBox(height: 14),
            SelectField(
                label: 'Specialty',
                value: _specialty,
                options: kSpecialties,
                error: _err['specialty'],
                onChanged: (v) => setState(() => _specialty = v)),
            const SizedBox(height: 14),
            LabeledField(
                label: 'Phone (optional)',
                controller: _phone,
                hint: '+94 71 123 4567',
                keyboard: TextInputType.phone,
                error: _err['phone']),
            const SizedBox(height: 14),
            LabeledField(
                label: 'Email (optional)',
                controller: _email,
                hint: 'doctor@hospital.lk',
                keyboard: TextInputType.emailAddress,
                error: _err['email']),
            const SizedBox(height: 14),
            SelectField(
                label: 'Availability',
                value: _status,
                options: const ['Active', 'On leave'],
                error: _err['status'],
                onChanged: (v) => setState(() => _status = v)),
            if (_error != null) ...[const SizedBox(height: 14), ErrorBanner(_error!)],
            const SizedBox(height: 16),
            SecondaryButton('Cancel', onPressed: () => Navigator.of(context).pop(false)),
            const SizedBox(height: 10),
            PrimaryButton(_isEdit ? 'Save Changes' : 'Add Doctor', onPressed: _save, loading: _saving),
          ]),
        ),
      ]),
    );
  }
}
