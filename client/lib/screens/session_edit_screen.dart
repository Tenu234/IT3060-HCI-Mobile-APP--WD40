import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Create / Edit / Delete an OPD session. Pass [session] to edit, null to create.
class SessionEditScreen extends StatefulWidget {
  final Map<String, dynamic>? session;
  const SessionEditScreen({super.key, this.session});
  @override
  State<SessionEditScreen> createState() => _SessionEditScreenState();
}

class _SessionEditScreenState extends State<SessionEditScreen> {
  final _room = TextEditingController();
  final _doctor = TextEditingController();
  final _date = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _max = TextEditingController();

  List<Map<String, dynamic>> _clinics = [];
  int? _clinicId;
  bool _saving = false;
  bool _loadingClinics = true;
  String? _error;
  Map<String, String> _err = {};

  bool get _isEdit => widget.session != null;
  Map<String, dynamic> get _s => widget.session ?? {};

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _clinicId = _s['clinic_id'] as int?;
      _room.text = '${_s['room']}';
      _doctor.text = '${_s['doctor']}';
      _date.text = '${_s['date']}';
      _start.text = '${_s['start_time']}';
      _end.text = '${_s['end_time']}';
      _max.text = '${_s['max_appointments']}';
    } else {
      _date.text = apiDate(DateTime.now());
      _start.text = '08:00';
      _end.text = '12:00';
      _max.text = '40';
    }
    _loadClinics();
  }

  @override
  void dispose() {
    for (final c in [_room, _doctor, _date, _start, _end, _max]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadClinics() async {
    try {
      final r = await Api.i.get('/clinics');
      if (!mounted) return;
      setState(() => _clinics = (r['clinics'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingClinics = false);
    }
  }

  String? get _clinicLabel {
    for (final c in _clinics) {
      if (c['id'] == _clinicId) return '${c['name']} · ${c['hospital']}';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date.text) ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d != null) setState(() => _date.text = apiDate(d));
  }

  Future<void> _pickTime(TextEditingController c) async {
    final parts = c.text.split(':');
    final initial = parts.length == 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 8, minute: 0);
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t != null) setState(() => c.text = hhmm(t));
  }

  Map<String, dynamic> _body() => {
        'clinic_id': _clinicId,
        'room': _room.text.trim(),
        'doctor': _doctor.text.trim(),
        'date': _date.text.trim(),
        'start_time': _start.text.trim(),
        'end_time': _end.text.trim(),
        'max_appointments': int.tryParse(_max.text.trim()) ?? 0,
      };

  Future<void> _save() async {
    // quick client-side checks; the server re-validates everything
    final e = <String, String>{};
    if (_clinicId == null) e['clinic_id'] = 'Select a clinic.';
    if (_room.text.trim().isEmpty) e['room'] = 'Room is required.';
    if (_doctor.text.trim().isEmpty) e['doctor'] = 'Assigned doctor is required.';
    if (_start.text.compareTo(_end.text) >= 0) e['end_time'] = 'End time must be after start time.';
    final max = int.tryParse(_max.text.trim());
    if (max == null || max < 1) e['max_appointments'] = 'Enter a number of 1 or more.';
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
    try {
      try {
        await _send(_body());
      } on ApiException catch (ex) {
        if (!ex.needsConfirmation) rethrow;
        if (!mounted) return;
        final ok = await confirmDialog(context,
            title: 'Confirm changes', message: ex.message, confirm: 'Save anyway');
        if (!ok) return;
        await _send({..._body(), 'confirm': true});
      }
      if (!mounted) return;
      snack(context, _isEdit ? 'Session updated' : 'Session created');
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

  Future<void> _send(Map<String, dynamic> body) =>
      _isEdit ? Api.i.put('/sessions/${_s['id']}', body) : Api.i.post('/sessions', body);

  Future<void> _delete() async {
    final ok = await confirmDialog(context,
        title: 'Delete session?',
        message: 'This permanently removes the session. Sessions with bookings cannot be deleted - close them instead.',
        confirm: 'Delete',
        danger: true);
    if (!ok) return;
    try {
      await Api.i.delete('/sessions/${_s['id']}');
      if (!mounted) return;
      snack(context, 'Session deleted');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booked = _isEdit ? (_s['booked'] ?? 0) : 0;
    final cap = _max.text.isEmpty ? '-' : _max.text;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEdit ? 'Edit OPD Session' : 'New OPD Session',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const Text('National Hospital OPD Admin', style: TextStyle(fontSize: 12, color: C.muted)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: C.blueSoft, borderRadius: BorderRadius.circular(20)),
            child: const Text('Admin', style: TextStyle(color: C.brand, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _loadingClinics
                ? const LinearProgressIndicator()
                : SelectField(
                    label: 'Clinic Name / Type',
                    value: _clinicLabel,
                    hint: 'Select clinic',
                    options: [for (final c in _clinics) '${c['name']} · ${c['hospital']}'],
                    error: _err['clinic_id'],
                    onChanged: (v) {
                      final i = _clinics.indexWhere((c) => '${c['name']} · ${c['hospital']}' == v);
                      if (i >= 0) {
                        setState(() {
                          _clinicId = _clinics[i]['id'] as int;
                          if (_room.text.isEmpty) _room.text = '${_clinics[i]['room'] ?? ''}';
                          if (_doctor.text.isEmpty) _doctor.text = '${_clinics[i]['doctor'] ?? ''}';
                        });
                      }
                    }),
            const SizedBox(height: 14),
            LabeledField(label: 'Room', controller: _room, hint: 'e.g. Room 14', error: _err['room']),
            const SizedBox(height: 14),
            LabeledField(label: 'Assigned Doctor', controller: _doctor, hint: 'e.g. Dr. Nadeesha Fernando', error: _err['doctor']),
            const SizedBox(height: 14),
            LabeledField(
                label: 'Session Date',
                controller: _date,
                readOnly: true,
                onTap: _pickDate,
                error: _err['date'],
                suffix: const Icon(Icons.calendar_today_outlined, color: C.muted)),
            const SizedBox(height: 14),
            LabeledField(
                label: 'Start Time',
                controller: _start,
                readOnly: true,
                onTap: () => _pickTime(_start),
                error: _err['start_time'],
                suffix: const Icon(Icons.access_time, color: C.muted)),
            const SizedBox(height: 14),
            LabeledField(
                label: 'End Time',
                controller: _end,
                readOnly: true,
                onTap: () => _pickTime(_end),
                error: _err['end_time'],
                suffix: const Icon(Icons.access_time, color: C.muted)),
            const SizedBox(height: 14),
            LabeledField(
                label: 'Maximum Appointments',
                controller: _max,
                keyboard: TextInputType.number,
                error: _err['max_appointments'],
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 16),
            if (_isEdit)
              Panel(
                color: C.blueSoft,
                borderColor: C.blueSoft,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Current booked count: $booked · Capacity: $cap', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  StatusChip('${_s['display_status']}'),
                  const SizedBox(height: 6),
                  const Text('Changes affecting existing bookings require confirmation before saving.',
                      style: TextStyle(color: C.muted, fontSize: 13)),
                ]),
              ),
            if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
            const SizedBox(height: 14),
            SecondaryButton('Cancel', onPressed: () => Navigator.of(context).pop(false)),
            const SizedBox(height: 10),
            PrimaryButton(_isEdit ? 'Save Changes' : 'Create Session', onPressed: _save, loading: _saving),
            if (_isEdit) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, color: C.red),
                  label: const Text('Delete session', style: TextStyle(color: C.red)),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
