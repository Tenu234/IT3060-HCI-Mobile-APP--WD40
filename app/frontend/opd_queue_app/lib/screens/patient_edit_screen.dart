import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Add / Edit a patient record. NIC can only be entered when adding.
class PatientEditScreen extends StatefulWidget {
  final Map<String, dynamic>? patient;
  const PatientEditScreen({super.key, this.patient});
  @override
  State<PatientEditScreen> createState() => _PatientEditScreenState();
}

class _PatientEditScreenState extends State<PatientEditScreen> {
  final _name = TextEditingController();
  final _nic = TextEditingController();
  final _age = TextEditingController();
  final _mobile = TextEditingController();
  final _notes = TextEditingController();
  String? _gender;
  String _blood = 'Unknown';
  bool _saving = false;
  String? _error;
  Map<String, String> _err = {};
  static const _groups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'];

  bool get _isEdit => widget.patient != null;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    if (p != null) {
      _name.text = '${p['full_name']}';
      _nic.text = '${p['nic_masked']}';
      _age.text = '${p['age']}';
      _gender = '${p['gender']}';
      final m = '${p['mobile']}';
      _mobile.text = m.startsWith('+94') ? m.substring(3) : m;
      _blood = '${p['blood_group'] ?? 'Unknown'}';
      _notes.text = '${p['clinical_notes'] ?? ''}';
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _nic, _age, _mobile, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _localMobile {
    final d = _mobile.text.replaceAll(RegExp(r'\D'), '');
    return d.startsWith('0') ? d.substring(1) : d;
  }

  Future<void> _save() async {
    final e = <String, String>{};
    if (_name.text.trim().length < 3) e['full_name'] = 'Enter the patient\'s full name.';
    if (!_isEdit && !RegExp(r'^(\d{9}[VvXx]|\d{12})$').hasMatch(_nic.text.trim())) {
      e['nic'] = 'NIC must be 12 digits, or 9 digits followed by V/X.';
    }
    final age = int.tryParse(_age.text.trim());
    if (age == null || age < 0 || age > 120) e['age'] = 'Enter a valid age.';
    if (_gender == null) e['gender'] = 'Select a gender.';
    if (_localMobile.length != 9) e['mobile'] = 'Enter a valid mobile, e.g. 77 123 4567.';
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
      'full_name': _name.text.trim(),
      if (!_isEdit) 'nic': _nic.text.trim(),
      'age': age,
      'gender': _gender,
      'mobile': '+94$_localMobile',
      'blood_group': _blood,
      'clinical_notes': _notes.text.trim(),
    };
    try {
      if (_isEdit) {
        await Api.i.put('/admin/patients/${widget.patient!['id']}', body);
      } else {
        await Api.i.post('/admin/patients', body);
      }
      if (!mounted) return;
      snack(context, _isEdit ? 'Patient updated' : 'Patient added');
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
          Text(_isEdit ? 'Edit Patient' : 'Add Patient',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          Text(_isEdit ? '${widget.patient!['reg_id']}' : 'OPD Admin',
              style: const TextStyle(fontSize: 12, color: C.muted)),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LabeledField(label: 'Full Name', controller: _name, hint: 'As shown on NIC', error: _err['full_name']),
            const SizedBox(height: 14),
            LabeledField(
                label: _isEdit ? 'NIC (cannot be changed)' : 'NIC / National ID',
                controller: _nic,
                hint: '200012345678',
                enabled: !_isEdit,
                error: _err['nic']),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: LabeledField(
                    label: 'Age', controller: _age, hint: 'Age', keyboard: TextInputType.number, error: _err['age']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectField(
                    label: 'Gender',
                    value: _gender,
                    options: const ['Male', 'Female', 'Other'],
                    error: _err['gender'],
                    onChanged: (v) => setState(() => _gender = v)),
              ),
            ]),
            const SizedBox(height: 14),
            LabeledField(
                label: 'Mobile Number',
                controller: _mobile,
                hint: '77 123 4567',
                prefix: '+94',
                keyboard: TextInputType.phone,
                error: _err['mobile']),
            const SizedBox(height: 14),
            SelectField(
                label: 'Blood group',
                value: _blood,
                options: _groups,
                error: _err['blood_group'],
                onChanged: (v) => setState(() => _blood = v)),
            const SizedBox(height: 14),
            const Text('Clinical notes (staff-only)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
                controller: _notes,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(hintText: 'Allergies, conditions, follow-up notes...')),
            if (_error != null) ...[const SizedBox(height: 8), ErrorBanner(_error!)],
            const SizedBox(height: 16),
            SecondaryButton('Cancel', onPressed: () => Navigator.of(context).pop(false)),
            const SizedBox(height: 10),
            PrimaryButton(_isEdit ? 'Save Changes' : 'Add Patient', onPressed: _save, loading: _saving),
          ]),
        ),
      ]),
    );
  }
}
