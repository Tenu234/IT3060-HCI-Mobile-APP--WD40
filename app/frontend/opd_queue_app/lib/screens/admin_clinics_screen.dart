import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/admin_menu.dart';
import '../widgets/common.dart';
import 'clinic_edit_screen.dart';

/// Admin: manage OPD clinics - Add, Edit, Delete, Put on hold / Resume.
class AdminClinicsScreen extends StatefulWidget {
  const AdminClinicsScreen({super.key});
  @override
  State<AdminClinicsScreen> createState() => _AdminClinicsScreenState();
}

class _AdminClinicsScreenState extends State<AdminClinicsScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  String _status = 'All';
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  static const _statuses = ['All', 'Active', 'On hold'];

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
      final r = await Api.i.get('/admin/clinics', {'q': _q.text.trim(), 'status': _status});
      if (!mounted) return;
      setState(() => _items = (r['clinics'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? c]) async {
    final changed = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => ClinicEditScreen(clinic: c)));
    if (changed == true) _load();
  }

  Future<void> _hold(Map<String, dynamic> c) async {
    final reason = TextEditingController();
    final upcoming = c['upcoming_bookings'] ?? 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Put clinic on hold?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Patients will not be able to see slots or book ${c['name']} until you resume it.'
              '${upcoming > 0 ? '\n\n$upcoming upcoming booking(s) are kept - contact those patients if needed.' : ''}'),
          const SizedBox(height: 12),
          TextField(
              controller: reason,
              maxLength: 200,
              decoration: const InputDecoration(hintText: 'Reason (optional), e.g. Doctor on leave')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Put on hold', style: TextStyle(color: C.amber, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    final text = reason.text;
    reason.dispose();
    if (ok != true) return;
    try {
      await Api.i.patch('/admin/clinics/${c['id']}/hold', {'reason': text});
      if (!mounted) return;
      snack(context, '${c['name']} is now on hold');
      _load();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  Future<void> _resume(Map<String, dynamic> c) async {
    try {
      await Api.i.patch('/admin/clinics/${c['id']}/resume', {});
      if (!mounted) return;
      snack(context, '${c['name']} resumed');
      _load();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> c) async {
    final ok = await confirmDialog(context,
        title: 'Delete clinic?',
        message:
            '${c['name']} at ${c['hospital']} and all of its sessions will be permanently deleted. Clinics with upcoming bookings cannot be deleted - put them on hold instead.',
        confirm: 'Delete',
        danger: true);
    if (!ok) return;
    try {
      await Api.i.delete('/admin/clinics/${c['id']}');
      if (!mounted) return;
      snack(context, 'Clinic deleted');
      _load();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpdAppBar(
          title: 'OPD Admin', subtitle: 'Manage clinics', showBack: false, actions: [AdminMenuButton()]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.brand,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add clinic'),
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
                hintText: 'Hospital, clinic, district or doctor', prefixIcon: Icon(Icons.search, color: C.muted)),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final s in _statuses)
              FilterPill(
                label: s,
                active: _status == s,
                dot: s == 'On hold' ? C.amber : (s == 'Active' ? C.green : null),
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
              icon: Icons.local_hospital_outlined,
              title: 'No clinics found',
              message: 'Add your first OPD clinic or change the filters.',
              actionLabel: 'Add clinic',
              onAction: () => _openEditor(),
            )
          else ...[
            Text('${_items.length} clinic${_items.length == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final c in _items) _card(c),
          ],
        ]),
      ),
    );
  }

  Widget _card(Map<String, dynamic> c) {
    final onHold = c['status'] == 'on_hold';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        borderColor: onHold ? const Color(0xFFF0DC7A) : C.border,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${c['name']}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                Text('${c['hospital']} · ${c['district']}', style: const TextStyle(color: C.muted)),
              ]),
            ),
            StatusChip(onHold ? 'On hold' : 'Active'),
          ]),
          if (onHold && '${c['hold_reason'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: C.yellowSoft, borderRadius: BorderRadius.circular(10)),
              child: Text('Reason: ${c['hold_reason']}', style: const TextStyle(color: C.amber, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 10),
          KeyValueRow('Doctor', '${c['doctor_name'] ?? 'Not assigned'}'),
          KeyValueRow('Room', '${c['room'] ?? '-'}'),
          KeyValueRow('Hours', '${c['days']} · ${c['open_time']}-${c['close_time']}'),
          KeyValueRow('Upcoming bookings', '${c['upcoming_bookings']}'),
          KeyValueRow('Open sessions', '${c['upcoming_sessions']}'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: SecondaryButton('Edit', fill: C.blueSoft, onPressed: () => _openEditor(c))),
            const SizedBox(width: 10),
            Expanded(
              child: onHold
                  ? SecondaryButton('Resume', color: C.green, onPressed: () => _resume(c))
                  : SecondaryButton('Put on hold', color: C.amber, onPressed: () => _hold(c)),
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
                onPressed: () => _delete(c),
                child: const Icon(Icons.delete_outline, color: C.red),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
