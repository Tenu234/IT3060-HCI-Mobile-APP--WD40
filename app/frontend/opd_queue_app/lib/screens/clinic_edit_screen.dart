import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';

const kDistricts = [
  'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle', 'Gampaha', 'Hambantota', 'Jaffna',
  'Kalutara', 'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Monaragala',
  'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya',
];

/// Add / Edit an OPD clinic. Pass [clinic] to edit.
class ClinicEditScreen extends StatefulWidget {
  final Map<String, dynamic>? clinic;
  const ClinicEditScreen({super.key, this.clinic});
  @override
  State<ClinicEditScreen> createState() => _ClinicEditScreenState();
}

class _ClinicEditScreenState extends State<ClinicEditScreen> {
  static const _none = '— No doctor assigned —';
  final _hospital = TextEditingController();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _room = TextEditingController();
  final _desc = TextEditingController();
  final _open = TextEditingController(text: '08:00');
  final _close = TextEditingController(text: '16:00');
  String? _district;
  String _days = 'Mon-Fri';
  int? _doctorId;
  List<Map<String, dynamic>> _doctors = [];
  bool _loadingDocs = true;
  bool _saving = false;
  String? _error;
  Map<String, String> _err = {};

  bool get _isEdit => widget.clinic != null;

  @override
  void initState() {
    super.initState();
    final c = widget.clinic;
    if (c != null) {
      _hospital.text = '${c['hospital']}';
      _name.text = '${c['name']}';
      _code.text = '${c['code'] ?? ''}';
      _room.text = '${c['room'] ?? ''}';
      _desc.text = '${c['description'] ?? ''}';
      _open.text = '${c['open_time']}';
      _close.text = '${c['close_time']}';
      _district = '${c['district']}';
      _days = '${c['days']}';
      _doctorId = c['doctor_id'] as int?;
    }
    _loadDoctors();
  }

  @override
  void dispose() {
    for (final c in [_hospital, _name, _code, _room, _desc, _open, _close]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    try {
      final r = await Api.i.get('/admin/doctors');
      if (!mounted) return;
      setState(() => _doctors = (r['doctors'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingDocs = false);
    }
  }

  String _docLabel(Map<String, dynamic> d) =>
      '${d['name']} · ${d['specialty']}${d['status'] == 'on_leave' ? ' (On leave)' : ''}';

  String? get _doctorValue {
    if (_doctorId == null) return _none;
    for (final d in _doctors) {
      if (d['id'] == _doctorId) return _docLabel(d);
    }
    return null;
  }

  Future<void> _pickTime(TextEditingController c) async {
    final p = c.text.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(p[0]) ?? 8, minute: p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0),
    );
    if (t != null) setState(() => c.text = hhmm(t));
  }

  Future<void> _save() async {
    final e = <String, String>{};
    if (_hospital.text.trim().length < 3) e['hospital'] = 'Enter the hospital name.';
    if (_name.text.trim().length < 2) e['name'] = 'Enter the clinic name.';
    if (_district == null) e['district'] = 'Select a district.';
    if (_code.text.trim().isNotEmpty && !RegExp(r'^[A-Za-z]{1,3}$').hasMatch(_code.text.trim())) {
      e['code'] = 'Token prefix must be 1-3 letters.';
    }
    if (_open.text.compareTo(_close.text) >= 0) e['close_time'] = 'Closing time must be after opening time.';
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
      'hospital': _hospital.text.trim(),
      'name': _name.text.trim(),
      'code': _code.text.trim(),
      'district': _district,
      'room': _room.text.trim(),
      'doctor_id': _doctorId,
      'description': _desc.text.trim(),
      'days': _days,
      'open_time': _open.text,
      'close_time': _close.text,
    };
    try {
      if (_isEdit) {
        await Api.i.put('/admin/clinics/${widget.clinic!['id']}', body);
      } else {
        await Api.i.post('/admin/clinics', body);
      }
      if (!mounted) return;
      snack(context, _isEdit ? 'Clinic updated' : 'Clinic added');
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
    final docLabels = [_none, for (final d in _doctors) _docLabel(d)];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEdit ? 'Edit OPD Clinic' : 'Add OPD Clinic',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const Text('OPD Admin', style: TextStyle(fontSize: 12, color: C.muted)),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LabeledField(
                label: 'Hospital',
                controller: _hospital,
                hint: 'e.g. National Hospital of Sri Lanka',
                error: _err['hospital']),
            const SizedBox(height: 14),
            LabeledField(
                label: 'Clinic Name / Type', controller: _name, hint: 'e.g. General OPD', error: _err['name']),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 3,
                child: SelectField(
                    label: 'District',
                    value: _district,
                    options: kDistricts,
                    error: _err['district'],
                    onChanged: (v) => setState(() => _district = v)),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: LabeledField(
                    label: 'Token prefix', controller: _code, hint: 'A', error: _err['code']),
              ),
            ]),
            const SizedBox(height: 14),
            LabeledField(label: 'Room', controller: _room, hint: 'e.g. Room 14', error: _err['room']),
            const SizedBox(height: 14),
            _loadingDocs
                ? const LinearProgressIndicator()
                : SelectField(
                    label: 'Assigned Doctor',
                    value: _doctorValue,
                    hint: 'Select doctor',
                    options: docLabels,
                    error: _err['doctor_id'],
                    onChanged: (v) {
                      final i = _doctors.indexWhere((d) => _docLabel(d) == v);
                      setState(() => _doctorId = i >= 0 ? _doctors[i]['id'] as int : null);
                    }),
            const SizedBox(height: 14),
            SelectField(
                label: 'Operating days',
                value: _days,
                options: const ['Mon-Fri', 'Mon-Sat', 'Mon-Sun'],
                error: _err['days'],
                onChanged: (v) => setState(() => _days = v)),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: LabeledField(
                    label: 'Opens',
                    controller: _open,
                    readOnly: true,
                    onTap: () => _pickTime(_open),
                    error: _err['open_time'],
                    suffix: const Icon(Icons.access_time, color: C.muted)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledField(
                    label: 'Closes',
                    controller: _close,
                    readOnly: true,
                    onTap: () => _pickTime(_close),
                    error: _err['close_time'],
                    suffix: const Icon(Icons.access_time, color: C.muted)),
              ),
            ]),
            const SizedBox(height: 14),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'What does this clinic treat?')),
            if (_error != null) ...[const SizedBox(height: 14), ErrorBanner(_error!)],
            const SizedBox(height: 16),
            SecondaryButton('Cancel', onPressed: () => Navigator.of(context).pop(false)),
            const SizedBox(height: 10),
            PrimaryButton(_isEdit ? 'Save Changes' : 'Add Clinic', onPressed: _save, loading: _saving),
          ]),
        ),
      ]),
    );
  }
}
