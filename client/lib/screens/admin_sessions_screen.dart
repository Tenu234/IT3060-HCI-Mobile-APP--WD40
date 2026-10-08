import 'dart:async';
import 'package:flutter/material.dart';
import '../router.dart';
import '../services/api.dart';
import '../services/auth.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'session_edit_screen.dart';
import 'staff_patient_search_screen.dart';

/// Admin OPD Management - list sessions with Create / Read / Update / Close / Delete.
class AdminSessionsScreen extends StatefulWidget {
  const AdminSessionsScreen({super.key});
  @override
  State<AdminSessionsScreen> createState() => _AdminSessionsScreenState();
}

class _AdminSessionsScreenState extends State<AdminSessionsScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  DateTime? _date = DateTime.now();
  String _status = 'All statuses';
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  String? _error;
  static const _statuses = ['All statuses', 'Active', 'Upcoming', 'Full', 'Completed', 'Closed'];

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
      final r = await Api.i.get('/sessions', {
        'q': _q.text.trim(),
        'date': _date == null ? '' : apiDate(_date!),
        'status': _status == 'All statuses' ? '' : _status,
      });
      if (!mounted) return;
      setState(() {
        _summary = Map<String, dynamic>.from(r['summary'] as Map);
        _sessions = (r['sessions'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) {
      _date = d;
      _load();
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? s]) async {
    final changed = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => SessionEditScreen(session: s)));
    if (changed == true) _load();
  }

  Future<void> _close(Map<String, dynamic> s) async {
    final ok = await confirmDialog(context,
        title: 'Close session?',
        message: 'Patients will no longer be able to book ${s['clinic_name']} on ${longDate(s['date'])}.',
        confirm: 'Close session',
        danger: true);
    if (!ok) return;
    try {
      try {
        await Api.i.patch('/sessions/${s['id']}/close', {});
      } on ApiException catch (e) {
        if (!e.needsConfirmation) rethrow;
        if (!mounted) return;
        final again = await confirmDialog(context,
            title: 'Existing bookings', message: e.message, confirm: 'Close anyway', danger: true);
        if (!again) return;
        await Api.i.patch('/sessions/${s['id']}/close', {'confirm': true});
      }
      if (!mounted) return;
      snack(context, 'Session closed');
      _load();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  Future<void> _reopen(Map<String, dynamic> s) async {
    try {
      await Api.i.patch('/sessions/${s['id']}/reopen', {});
      if (!mounted) return;
      snack(context, 'Session reopened');
      _load();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  String get _initials {
    final parts = '${Auth.i.user?['full_name'] ?? 'A'}'.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.local_hospital, color: C.brand),
              title: const Text('OPD Admin', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${Auth.i.user?['full_name'] ?? ''}'),
            ),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.event_note),
                title: const Text('OPD Sessions'),
                onTap: () => Navigator.pop(context)),
            ListTile(
              leading: const Icon(Icons.person_search),
              title: const Text('Patient search & history'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StaffPatientSearchScreen()));
              },
            ),
            const Spacer(),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Log out'), onTap: () => doLogout(context)),
          ]),
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 64,
        leading: Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              style: IconButton.styleFrom(backgroundColor: C.blueSoft, foregroundColor: C.brand),
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        title: const Text('OPD Sessions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              backgroundColor: C.ink,
              child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.brand,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New session'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
          Row(children: [
            Expanded(child: _stat('Active sessions', '${_summary['active_sessions'] ?? 0}')),
            const SizedBox(width: 10),
            Expanded(child: _stat('Booked appointments', '${_summary['booked_appointments'] ?? 0}')),
            const SizedBox(width: 10),
            Expanded(child: _stat('Doctors on duty', '${_summary['doctors_on_duty'] ?? 0}')),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _q,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), _load);
            },
            decoration: const InputDecoration(
                hintText: 'Clinic, room or doctor', prefixIcon: Icon(Icons.search, color: C.muted)),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: C.muted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_date == null ? 'All dates' : longDate(apiDate(_date!)), overflow: TextOverflow.ellipsis)),
                    if (_date != null)
                      InkWell(
                        onTap: () {
                          _date = null;
                          _load();
                        },
                        child: const Icon(Icons.close, size: 18, color: C.muted),
                      ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SelectField(
                  value: _status,
                  options: _statuses,
                  leading: Icons.filter_alt_outlined,
                  onChanged: (v) {
                    _status = v;
                    _load();
                  }),
            ),
          ]),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_error != null) ...[
            ErrorBanner(_error!),
            const SizedBox(height: 12),
            SecondaryButton('Try again', onPressed: _load),
          ] else if (_sessions.isEmpty)
            EmptyState(
              icon: Icons.event_busy,
              title: 'No sessions found',
              message: 'No OPD sessions match these filters.',
              actionLabel: 'Create a session',
              onAction: () => _openEditor(),
            )
          else
            for (final s in _sessions) _card(s),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: C.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _card(Map<String, dynamic> s) {
    final closed = s['status'] == 'closed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s['clinic_name']}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                Text('${s['room']} · ${s['hospital']}', style: const TextStyle(color: C.muted)),
              ]),
            ),
            StatusChip('${s['display_status']}'),
          ]),
          const SizedBox(height: 10),
          KeyValueRow('Doctor', '${s['doctor']}'),
          KeyValueRow('Date', longDate(s['date'])),
          KeyValueRow('Time', '${s['start_time']}-${s['end_time']}'),
          KeyValueRow('Booked / Capacity', '${s['booked']} / ${s['max_appointments']}'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: SecondaryButton('Edit', fill: C.blueSoft, onPressed: () => _openEditor(s))),
            const SizedBox(width: 12),
            Expanded(
              child: closed
                  ? SecondaryButton('Reopen', onPressed: () => _reopen(s))
                  : SecondaryButton('Close', onPressed: () => _close(s)),
            ),
          ]),
        ]),
      ),
    );
  }
}
