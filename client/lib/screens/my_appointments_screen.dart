import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});
  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Api.i.get('/appointments/mine');
      if (mounted) setState(() => _items = r['appointments'] as List);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(Map a) async {
    final ok = await confirmDialog(context,
        title: 'Cancel appointment?',
        message: 'Token ${a['token']} on ${longDate(a['date'])} will be cancelled.',
        confirm: 'Cancel appointment',
        danger: true);
    if (!ok) return;
    try {
      await Api.i.put('/appointments/${a['id']}/cancel');
      if (!mounted) return;
      snack(context, 'Appointment cancelled');
      _load();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpdAppBar(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Heading('My appointments'),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            ErrorBanner(_error!)
          else if (_items.isEmpty)
            const EmptyState(icon: Icons.event_note, title: 'No appointments yet', message: 'Book a slot from OPD Search.')
          else
            for (final raw in _items)
              Builder(builder: (_) {
                final a = Map<String, dynamic>.from(raw as Map);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(longDate(a['date']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        StatusChip(a['status'].toString()[0].toUpperCase() + a['status'].toString().substring(1)),
                      ]),
                      const SizedBox(height: 6),
                      KeyValueRow('Clinic', '${a['clinic_name']}'),
                      KeyValueRow('Hospital', '${a['hospital']}'),
                      KeyValueRow('Time', '${a['start_time']}-${a['end_time']}'),
                      KeyValueRow('Token', '${a['token']}'),
                      if (a['status'] == 'booked') ...[
                        const SizedBox(height: 8),
                        SecondaryButton('Cancel appointment', color: C.red, onPressed: () => _cancel(a)),
                      ],
                    ]),
                  ),
                );
              }),
        ]),
      ),
    );
  }
}
