import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/admin_menu.dart';
import '../widgets/common.dart';
import 'patient_edit_screen.dart';
import 'patient_history_screen.dart';

/// Admin: patient records - Add, Edit, Delete, view visit history.
class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key});
  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Api.i.get('/admin/patients', {'q': _q.text.trim()});
      if (!mounted) return;
      setState(() => _items = (r['patients'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? p]) async {
    final changed = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => PatientEditScreen(patient: p)));
    if (changed == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    final ok = await confirmDialog(context,
        title: 'Delete patient?',
        message:
            '${p['full_name']} and their full visit history will be permanently deleted. Patients with upcoming bookings cannot be deleted.',
        confirm: 'Delete',
        danger: true);
    if (!ok) return;
    try {
      await Api.i.delete('/admin/patients/${p['id']}');
      if (!mounted) return;
      snack(context, 'Patient deleted');
      _load();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpdAppBar(
          title: 'OPD Admin', subtitle: 'Patients', showBack: false, actions: [AdminMenuButton()]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.brand,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add patient'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
          TextField(
            controller: _q,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), _load);
            },
            decoration: const InputDecoration(
                hintText: 'Name, NIC, registration ID or mobile',
                prefixIcon: Icon(Icons.search, color: C.muted)),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_error != null) ...[
            ErrorBanner(_error!),
            const SizedBox(height: 12),
            SecondaryButton('Try again', onPressed: _load),
          ] else if (_items.isEmpty)
            EmptyState(
              icon: Icons.person_search_outlined,
              title: 'No patients found',
              message: 'Add a patient record or change your search.',
              actionLabel: 'Add patient',
              onAction: () => _openEditor(),
            )
          else ...[
            Text('${_items.length} patient${_items.length == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final p in _items) _card(p),
          ],
        ]),
      ),
    );
  }

  Widget _card(Map<String, dynamic> p) {
    final upcoming = p['upcoming_bookings'] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p['full_name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('${p['reg_id']} · NIC ${p['nic_masked']}',
                    style: const TextStyle(color: C.muted, fontSize: 13)),
              ]),
            ),
            if (upcoming > 0) StatusChip('Booked'),
          ]),
          const SizedBox(height: 10),
          KeyValueRow('Age / Gender', '${p['age']} · ${p['gender']}'),
          KeyValueRow('Mobile', '${p['mobile']}'),
          KeyValueRow('Blood group', '${p['blood_group']}'),
          KeyValueRow('Visits / Upcoming', '${p['total_visits']} / $upcoming'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: SecondaryButton('History',
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PatientHistoryScreen(patientId: p['id'] as int)))),
            ),
            const SizedBox(width: 10),
            Expanded(child: SecondaryButton('Edit', fill: C.blueSoft, onPressed: () => _openEditor(p))),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              width: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: C.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _delete(p),
                child: const Icon(Icons.delete_outline, color: C.red),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
