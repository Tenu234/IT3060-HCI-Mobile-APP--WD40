import 'package:flutter/material.dart';
import '../router.dart';
import '../services/api.dart';
import '../services/auth.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Booking confirmation (integration point with the Appointment Booking module).
class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> clinic;
  final Map<String, dynamic> slot;
  final Map<String, dynamic>? patient;
  const BookingScreen(
      {super.key, required this.clinic, required this.slot, this.patient});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _done;
  int? _queueNo;

  Future<void> _confirm() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Api.i.post('/appointments', {
        'session_id': widget.slot['id'],
        if (widget.patient != null) 'patient_id': widget.patient!['id'],
      });
      if (!mounted) return;
      setState(() {
        _done = Map<String, dynamic>.from(r['appointment'] as Map);
        _queueNo = r['queue_number'] as int?;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.patient?['full_name'] ?? Auth.i.user?['full_name'] ?? '';
    final s = widget.slot;
    final c = widget.clinic;
    if (_done != null) {
      return Scaffold(
        appBar: const OpdAppBar(showBack: false),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle, color: C.green, size: 72),
            const SizedBox(height: 12),
            const Text('Booking confirmed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Panel(
              child: Column(children: [
                KeyValueRow('Token', _done!['token'].toString()),
                if (_queueNo != null)
                  KeyValueRow('Queue position', '#$_queueNo'),
                KeyValueRow('Patient', name.toString()),
                KeyValueRow('Clinic', '${c['name']}'),
                KeyValueRow('Hospital', '${c['hospital']}'),
                KeyValueRow('Date', longDate(s['date'])),
                KeyValueRow('Time', '${s['start_time']}-${s['end_time']}'),
              ]),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              'Done',
              onPressed: () =>
                  goHome(context, tab: Auth.i.role == 'patient' ? 2 : null),
            ),
          ]),
        ),
      );
    }
    return Scaffold(
      appBar: const OpdAppBar(),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Heading('Confirm booking',
            subtitle: 'Review the details before confirming.'),
        const SizedBox(height: 16),
        Panel(
          child: Column(children: [
            KeyValueRow('Patient', name.toString()),
            KeyValueRow('Clinic', '${c['name']}'),
            KeyValueRow('Hospital', '${c['hospital']}'),
            KeyValueRow('Doctor', '${s['doctor']}'),
            KeyValueRow('Room', '${s['room']}'),
            KeyValueRow('Date', fullDate(s['date'])),
            KeyValueRow('Time', '${s['start_time']}-${s['end_time']}'),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('A queue number is assigned only after confirmed booking.',
            style: TextStyle(color: C.muted)),
        if (_error != null) ...[
          const SizedBox(height: 12),
          ErrorBanner(_error!)
        ],
        const SizedBox(height: 16),
        PrimaryButton('Confirm Booking',
            onPressed: _confirm, loading: _loading),
      ]),
    );
  }
}
