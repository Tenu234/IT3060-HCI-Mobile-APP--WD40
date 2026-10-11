import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/admin_menu.dart';
import '../widgets/common.dart';
import 'booking_create_screen.dart';
import 'patient_history_screen.dart';

/// Admin: booking list across all OPD clinics (Read / Update status / Delete).
class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});
  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  DateTime? _date;
  String _status = 'All statuses';
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  static const _statuses = ['All statuses', 'Booked', 'Completed', 'Cancelled'];

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
      final results = await Future.wait([
        Api.i.get('/admin/summary'),
        Api.i.get('/admin/bookings', {
          'q': _q.text.trim(),
          'date': _date == null ? '' : apiDate(_date!),
          'status': _status == 'All statuses' ? '' : _status,
        }),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0];
        _items = (results[1]['bookings'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) {
      _date = d;
      _load();
    }
  }

  Future<void> _newBooking() async {
    final created = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const BookingCreateScreen()));
    if (created == true) _load();
  }

  Future<void> _setStatus(Map<String, dynamic> b, String status) async {
    try {
      await Api.i.put('/admin/bookings/${b['id']}/status', {'status': status});
      if (!mounted) return;
      snack(context, 'Booking ${b['token']} marked ${status}');
      _load();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> b) async {
    final ok = await confirmDialog(context,
        title: 'Delete booking record?',
        message: 'Token ${b['token']} for ${b['patient_name']} will be permanently removed.',
        confirm: 'Delete',
        danger: true);
    if (!ok) return;
    try {
      await Api.i.delete('/admin/bookings/${b['id']}');
      if (!mounted) return;
      snack(context, 'Booking deleted');
      _load();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpdAppBar(
        title: 'OPD Admin',
        subtitle: 'Booking list',
        showBack: false,
        actions: [AdminMenuButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.brand,
        foregroundColor: Colors.white,
        onPressed: _newBooking,
        icon: const Icon(Icons.add),
        label: const Text('New booking'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
          Row(children: [
            Expanded(child: StatCard('Bookings today', '${_summary['bookings_today'] ?? 0}')),
            const SizedBox(width: 10),
            Expanded(child: StatCard('Upcoming', '${_summary['upcoming_bookings'] ?? 0}')),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard('Clinics on hold', '${_summary['clinics_on_hold'] ?? 0}',
                    valueColor: (_summary['clinics_on_hold'] ?? 0) > 0 ? C.amber : null)),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _q,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), _load);
            },
            decoration: const InputDecoration(
                hintText: 'Patient, token, clinic or doctor', prefixIcon: Icon(Icons.search, color: C.muted)),
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
                    Expanded(
                        child: Text(_date == null ? 'All dates' : longDate(apiDate(_date!)),
                            overflow: TextOverflow.ellipsis)),
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
          ] else if (_items.isEmpty)
            const EmptyState(
                icon: Icons.event_busy, title: 'No bookings found', message: 'No bookings match these filters.')
          else ...[
            Text('${_items.length} booking${_items.length == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final b in _items) _card(b),
          ],
        ]),
      ),
    );
  }

  Widget _card(Map<String, dynamic> b) {
    final status = capitalize('${b['status']}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${b['patient_name']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text('${b['reg_id'] ?? ''} · ${b['mobile']}', style: const TextStyle(color: C.muted, fontSize: 13)),
              ]),
            ),
            StatusChip(status),
            PopupMenuButton<String>(
              tooltip: 'Actions',
              icon: const Icon(Icons.more_vert, color: C.muted),
              onSelected: (v) {
                switch (v) {
                  case 'patient':
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PatientHistoryScreen(patientId: b['patient_id'] as int)));
                    break;
                  case 'delete':
                    _delete(b);
                    break;
                  default:
                    _setStatus(b, v);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'patient', child: Text('View patient history')),
                if (b['status'] != 'completed') const PopupMenuItem(value: 'completed', child: Text('Mark completed')),
                if (b['status'] != 'cancelled') const PopupMenuItem(value: 'cancelled', child: Text('Mark cancelled')),
                if (b['status'] != 'booked') const PopupMenuItem(value: 'booked', child: Text('Reset to booked')),
                const PopupMenuItem(value: 'delete', child: Text('Delete record', style: TextStyle(color: C.red))),
              ],
            ),
          ]),
          const Divider(height: 20),
          KeyValueRow('Token', '${b['token']}'),
          KeyValueRow('Clinic', '${b['clinic_name']}'),
          KeyValueRow('Hospital', '${b['hospital']}'),
          KeyValueRow('Doctor', '${b['doctor']}'),
          KeyValueRow('Date', longDate(b['date'])),
          KeyValueRow('Time', '${b['start_time']}-${b['end_time']}'),
        ]),
      ),
    );
  }
}
