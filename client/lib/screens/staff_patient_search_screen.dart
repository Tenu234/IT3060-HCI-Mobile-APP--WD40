import 'package:flutter/material.dart';
import '../router.dart';
import '../services/api.dart';
import '../services/auth.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'clinic_search_screen.dart';
import 'patient_history_screen.dart';

/// Authorized patient search (staff / admin only).
class StaffPatientSearchScreen extends StatefulWidget {
  const StaffPatientSearchScreen({super.key});
  @override
  State<StaffPatientSearchScreen> createState() => _StaffPatientSearchScreenState();
}

class _StaffPatientSearchScreenState extends State<StaffPatientSearchScreen> {
  final _q = TextEditingController();
  Map<String, dynamic>? _patient;
  List<Map<String, dynamic>> _visits = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_q.text.trim().isEmpty) {
      setState(() => _error = 'Enter a NIC or registration ID.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _patient = null;
    });
    try {
      final r = await Api.i.get('/patients/search', {'q': _q.text.trim()});
      if (!mounted) return;
      setState(() {
        _patient = Map<String, dynamic>.from(r['patient'] as Map);
        _visits = (r['visits'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // UPDATE: staff-only clinical details
  Future<void> _editClinical() async {
    final p = _patient!;
    String blood = p['blood_group'].toString();
    final notes = TextEditingController(text: '${p['clinical_notes'] ?? ''}');
    const groups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'];
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Clinical details'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SelectField(label: 'Blood group', value: blood, options: groups, onChanged: (v) => setS(() => blood = v)),
              const SizedBox(height: 12),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Clinical notes (staff-only)', style: TextStyle(fontWeight: FontWeight.w700))),
              const SizedBox(height: 8),
              TextField(controller: notes, maxLines: 4, maxLength: 1000),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    final text = notes.text;
    notes.dispose();
    if (save != true) return;
    try {
      final r = await Api.i.put('/patients/${p['id']}', {'blood_group': blood, 'clinical_notes': text});
      if (!mounted) return;
      setState(() => _patient = Map<String, dynamic>.from(r['patient'] as Map));
      snack(context, 'Clinical details saved');
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Auth.i.role == 'admin';
    return Scaffold(
      appBar: OpdAppBar(
        subtitle: 'Staff Portal',
        actions: [
          if (!isAdmin)
            IconButton(
                tooltip: 'Log out',
                icon: const Icon(Icons.logout, color: C.muted),
                onPressed: () => doLogout(context)),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Heading('Authorized patient search', subtitle: 'Search by NIC or registration ID. Staff access only.'),
        const SizedBox(height: 16),
        LabeledField(
          label: 'NIC or registration ID',
          controller: _q,
          hint: 'e.g. 199812345678 or REG-02481',
          keyboard: TextInputType.text,
        ),
        const SizedBox(height: 12),
        PrimaryButton('Search', onPressed: _search, loading: _loading),
        if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
        if (_patient != null) ...[
          const SizedBox(height: 16),
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Text('${_patient!['full_name']}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                IconButton(
                    tooltip: 'Edit clinical details',
                    icon: const Icon(Icons.edit_outlined, color: C.brand),
                    onPressed: _editClinical),
              ]),
              Text('${_patient!['reg_id']} · NIC ${_patient!['nic_masked']}', style: const TextStyle(color: C.muted)),
              const SizedBox(height: 6),
              Text('Blood group: ${_patient!['blood_group']} · Clinical notes: staff-only'),
              if ('${_patient!['clinical_notes'] ?? ''}'.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('${_patient!['clinical_notes']}', style: const TextStyle(color: C.muted)),
              ],
              const SizedBox(height: 10),
              SecondaryButton('View full profile & history',
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PatientHistoryScreen(patientId: _patient!['id'] as int)))),
            ]),
          ),
          const SizedBox(height: 18),
          const Text('Previous OPD visits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (_visits.isEmpty)
            const Panel(child: Text('No previous visits recorded.', style: TextStyle(color: C.muted)))
          else
            for (final v in _visits)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(longDate(v['date']), style: const TextStyle(fontWeight: FontWeight.w800)),
                      StatusChip(_cap('${v['status']}')),
                    ]),
                    const SizedBox(height: 6),
                    Text('${v['clinic_name']} · ${v['doctor']}', style: const TextStyle(color: C.muted)),
                    Text('Token ${v['token']}'),
                  ]),
                ),
              ),
          const SizedBox(height: 8),
          PrimaryButton('Book New OPD Token  →',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ClinicSearchScreen(bookForPatient: _patient)))),
        ],
      ]),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
