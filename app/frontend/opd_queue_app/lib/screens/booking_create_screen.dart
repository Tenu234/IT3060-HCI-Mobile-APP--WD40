import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'patient_edit_screen.dart';

/// Admin: create a booking (walk-in / phone) - choose patient, clinic, date and slot.
class BookingCreateScreen extends StatefulWidget {
  const BookingCreateScreen({super.key});
  @override
  State<BookingCreateScreen> createState() => _BookingCreateScreenState();
}

class _BookingCreateScreenState extends State<BookingCreateScreen> {
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _clinics = [];
  List<Map<String, dynamic>> _slots = [];
  int? _patientId;
  int? _clinicId;
  String? _date;
  int? _slotId;
  bool _loading = true;
  bool _loadingSlots = false;
  bool _saving = false;
  String? _error;
  Map<String, String> _err = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final r = await Future.wait([
        Api.i.get('/admin/patients'),
        Api.i.get('/admin/clinics', {'status': 'Active'}),
      ]);
      if (!mounted) return;
      setState(() {
        _patients = (r[0]['patients'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _clinics = (r[1]['clinics'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _pLabel(Map<String, dynamic> p) => '${p['full_name']} · ${p['reg_id']}';
  String _cLabel(Map<String, dynamic> c) => '${c['name']} · ${c['hospital']}';

  String? get _patientValue {
    for (final p in _patients) {
      if (p['id'] == _patientId) return _pLabel(p);
    }
    return null;
  }

  String? get _clinicValue {
    for (final c in _clinics) {
      if (c['id'] == _clinicId) return _cLabel(c);
    }
    return null;
  }

  Future<void> _loadSlots(int clinicId) async {
    setState(() {
      _loadingSlots = true;
      _slots = [];
      _date = null;
      _slotId = null;
    });
    try {
      final r = await Api.i.get('/clinics/$clinicId');
      if (!mounted) return;
      final slots = (r['slots'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _slots = slots;
        _date = slots.isEmpty ? null : slots.first['date'] as String;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  List<String> get _dates => _slots.map((s) => s['date'] as String).toSet().toList();
  List<Map<String, dynamic>> get _forDate => _slots.where((s) => s['date'] == _date).toList();

  Future<void> _addPatient() async {
    final added = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const PatientEditScreen()));
    if (added == true) {
      final r = await Api.i.get('/admin/patients');
      if (!mounted) return;
      final list = (r['patients'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _patients = list;
        // newest patient has the highest id - select it
        _patientId = list.map((p) => p['id'] as int).reduce((a, b) => a > b ? a : b);
      });
    }
  }

  Future<void> _confirm() async {
    final e = <String, String>{};
    if (_patientId == null) e['patient_id'] = 'Select a patient.';
    if (_clinicId == null) e['clinic_id'] = 'Select a clinic.';
    if (_clinicId != null && _slotId == null) e['session_id'] = 'Select an available time slot.';
    if (e.isNotEmpty) {
      setState(() {
        _err = e;
        _error = 'Please complete the highlighted fields.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _err = {};
    });
    try {
      final r = await Api.i.post('/admin/bookings', {'patient_id': _patientId, 'session_id': _slotId});
      if (!mounted) return;
      final b = Map<String, dynamic>.from(r['booking'] as Map);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Booking confirmed'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            KeyValueRow('Token', '${b['token']}'),
            KeyValueRow('Queue position', '#${r['queue_number']}'),
            KeyValueRow('Patient', '${b['patient_name']}'),
            KeyValueRow('Clinic', '${b['clinic_name']}'),
            KeyValueRow('Date', longDate(b['date'])),
            KeyValueRow('Time', '${b['start_time']}-${b['end_time']}'),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (ex) {
      if (mounted) {
        setState(() {
          _error = ex.message;
          _err = ex.fields;
        });
        // slot may have just filled up - refresh availability
        if (_clinicId != null) _loadSlots(_clinicId!);
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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('New Booking', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          Text('OPD Admin', style: TextStyle(fontSize: 12, color: C.muted)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SelectField(
                    label: 'Patient',
                    value: _patientValue,
                    hint: 'Select patient',
                    options: [for (final p in _patients) _pLabel(p)],
                    error: _err['patient_id'],
                    onChanged: (v) {
                      final i = _patients.indexWhere((p) => _pLabel(p) == v);
                      if (i >= 0) setState(() => _patientId = _patients[i]['id'] as int);
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                        onPressed: _addPatient,
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text('Add new patient')),
                  ),
                  const SizedBox(height: 6),
                  SelectField(
                    label: 'Clinic',
                    value: _clinicValue,
                    hint: _clinics.isEmpty ? 'No active clinics' : 'Select clinic',
                    options: [for (final c in _clinics) _cLabel(c)],
                    error: _err['clinic_id'],
                    onChanged: (v) {
                      final i = _clinics.indexWhere((c) => _cLabel(c) == v);
                      if (i >= 0) {
                        _clinicId = _clinics[i]['id'] as int;
                        _loadSlots(_clinicId!);
                      }
                    },
                  ),
                  if (_clinicId != null) ...[
                    const SizedBox(height: 18),
                    if (_loadingSlots)
                      const LinearProgressIndicator()
                    else if (_slots.isEmpty)
                      const EmptyState(
                          icon: Icons.event_busy,
                          title: 'No open sessions',
                          message: 'This clinic has no open sessions in the next 7 days. Add one in the Sessions tab.')
                    else ...[
                      const Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView(scrollDirection: Axis.horizontal, children: [
                          for (final d in _dates)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(chipDate(d)),
                                selected: _date == d,
                                selectedColor: C.brand,
                                backgroundColor: Colors.white,
                                showCheckmark: false,
                                labelStyle:
                                    TextStyle(color: _date == d ? Colors.white : C.ink, fontWeight: FontWeight.w700),
                                onSelected: (_) => setState(() {
                                  _date = d;
                                  _slotId = null;
                                }),
                              ),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      const Text('Time slot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      for (final s in _forDate) _slotTile(s),
                      if (_err['session_id'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 4),
                          child: Text(_err['session_id']!, style: const TextStyle(color: C.red, fontSize: 13)),
                        ),
                    ],
                  ],
                  if (_error != null) ...[const SizedBox(height: 14), ErrorBanner(_error!)],
                  const SizedBox(height: 16),
                  SecondaryButton('Cancel', onPressed: () => Navigator.of(context).pop(false)),
                  const SizedBox(height: 10),
                  PrimaryButton('Confirm Booking', onPressed: _confirm, loading: _saving),
                ]),
              ),
            ]),
    );
  }

  Widget _slotTile(Map<String, dynamic> s) {
    final full = s['full'] == true;
    final selected = _slotId == s['id'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: full ? null : () => setState(() => _slotId = s['id'] as int),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? C.blueSoft : (full ? const Color(0xFFF7F8FA) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? C.brand : C.border, width: selected ? 1.6 : 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${s['start_time']}-${s['end_time']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: full ? C.muted : C.ink)),
            full
                ? const StatusChip('Full')
                : Text('${s['left']} left', style: TextStyle(color: selected ? C.brand : C.green, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
