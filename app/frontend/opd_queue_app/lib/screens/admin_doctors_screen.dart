import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/admin_menu.dart';
import '../widgets/common.dart';
import 'doctor_edit_screen.dart';

/// Admin: doctor list - Add, Edit, Delete (and mark On leave).
class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});
  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  String _status = 'All';
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  static const _statuses = ['All', 'Active', 'On leave'];

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
      final r = await Api.i.get('/admin/doctors', {'q': _q.text.trim(), 'status': _status});
      if (!mounted) return;
      setState(() => _items = (r['doctors'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? d]) async {
    final changed = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => DoctorEditScreen(doctor: d)));
    if (changed == true) _load();
  }

  Future<void> _toggleLeave(Map<String, dynamic> d) async {
    final next = d['status'] == 'on_leave' ? 'active' : 'on_leave';
    try {
      await Api.i.put('/admin/doctors/${d['id']}', {'status': next});
      if (!mounted) return;
      snack(context, '${d['name']} marked ${next == 'active' ? 'active' : 'on leave'}');
      _load();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> d) async {
    final ok = await confirmDialog(context,
        title: 'Delete doctor?',
        message: '${d['name']} will be permanently removed. Doctors assigned to a clinic cannot be deleted.',
        confirm: 'Delete',
        danger: true);
    if (!ok) return;
    try {
      await Api.i.delete('/admin/doctors/${d['id']}');
      if (!mounted) return;
      snack(context, 'Doctor deleted');
      _load();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpdAppBar(
          title: 'OPD Admin', subtitle: 'Doctors', showBack: false, actions: [AdminMenuButton()]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.brand,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add doctor'),
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
                hintText: 'Name, specialty or clinic', prefixIcon: Icon(Icons.search, color: C.muted)),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final s in _statuses)
              FilterPill(
                label: s,
                active: _status == s,
                dot: s == 'On leave' ? C.amber : (s == 'Active' ? C.green : null),
                onTap: () {
                  _status = s;
                  _load();
                },
              ),
          ]),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_error != null) ...[
            ErrorBanner(_error!),
            const SizedBox(height: 12),
            SecondaryButton('Try again', onPressed: _load),
          ] else if (_items.isEmpty)
            EmptyState(
              icon: Icons.medical_services_outlined,
              title: 'No doctors found',
              message: 'Add a doctor or change the filters.',
              actionLabel: 'Add doctor',
              onAction: () => _openEditor(),
            )
          else ...[
            Text('${_items.length} doctor${_items.length == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final d in _items) _card(d),
          ],
        ]),
      ),
    );
  }

  Widget _card(Map<String, dynamic> d) {
    final onLeave = d['status'] == 'on_leave';
    final clinics = '${d['clinic_names'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: C.blueSoft,
              child: const Icon(Icons.medical_services, color: C.brand, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${d['name']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text('${d['specialty']}', style: const TextStyle(color: C.brand, fontWeight: FontWeight.w600)),
              ]),
            ),
            StatusChip(onLeave ? 'On leave' : 'Active'),
          ]),
          const SizedBox(height: 10),
          KeyValueRow('Phone', '${d['phone']}'.isEmpty ? '-' : '${d['phone']}'),
          KeyValueRow('Email', '${d['email']}'.isEmpty ? '-' : '${d['email']}'),
          KeyValueRow('Assigned clinics', clinics.isEmpty ? 'None' : clinics),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: SecondaryButton('Edit', fill: C.blueSoft, onPressed: () => _openEditor(d))),
            const SizedBox(width: 10),
            Expanded(
              child: onLeave
                  ? SecondaryButton('Mark active', color: C.green, onPressed: () => _toggleLeave(d))
                  : SecondaryButton('Mark on leave', color: C.amber, onPressed: () => _toggleLeave(d)),
            ),
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
                onPressed: () => _delete(d),
                child: const Icon(Icons.delete_outline, color: C.red),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
