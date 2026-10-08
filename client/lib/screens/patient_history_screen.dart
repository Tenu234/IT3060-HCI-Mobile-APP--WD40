import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Patient Profile & Visit History (authorized staff/admin view).
class PatientHistoryScreen extends StatefulWidget {
  final int patientId;
  const PatientHistoryScreen({super.key, required this.patientId});
  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  Map<String, dynamic>? _p;
  List<Map<String, dynamic>> _visits = [];
  bool _loading = true;
  String? _error;
  String _range = 'All time';
  final Set<int> _open = {};
  static const _ranges = ['All time', 'Last 30 days', 'Last 90 days', 'This year'];

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
      final r = await Api.i.get('/patients/${widget.patientId}');
      if (!mounted) return;
      setState(() {
        _p = Map<String, dynamic>.from(r['patient'] as Map);
        _visits = (r['visits'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final now = DateTime.now();
    DateTime? from;
    if (_range == 'Last 30 days') from = now.subtract(const Duration(days: 30));
    if (_range == 'Last 90 days') from = now.subtract(const Duration(days: 90));
    if (_range == 'This year') from = DateTime(now.year, 1, 1);
    if (from == null) return _visits;
    final f = from;
    return _visits.where((v) => !parseDate(v['date'] as String).isBefore(DateTime(f.year, f.month, f.day))).toList();
  }

  String _historyText() {
    final b = StringBuffer()
      ..writeln('GOVERNMENT HOSPITAL OPD - PATIENT HISTORY')
      ..writeln('Name: ${_p!['full_name']}')
      ..writeln('Reg ID: ${_p!['reg_id']}   NIC: ${_p!['nic_masked']}')
      ..writeln('Age: ${_p!['age']}   Gender: ${_p!['gender']}   Blood group: ${_p!['blood_group']}')
      ..writeln('Mobile: ${_p!['mobile']}')
      ..writeln('Range: $_range')
      ..writeln('------------------------------------------');
    for (final v in _filtered) {
      b.writeln('${longDate(v['date'])}  ${v['clinic_name']}  ${v['doctor']}  Token ${v['token']}  [${v['status']}]');
    }
    return b.toString();
  }

  void _print() {
    final text = _historyText();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Print patient history'),
        content: SingleChildScrollView(
          child: Text(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) snack(context, 'Copied. Paste into a document to print.');
            },
            child: const Text('Copy'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpdAppBar(subtitle: 'Authorized admin view · sensitive data safeguards enabled'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(padding: const EdgeInsets.all(16), child: ErrorBanner(_error!))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${_p!['full_name']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      Text('${_p!['reg_id']} · NIC ${_p!['nic_masked']}', style: const TextStyle(color: C.muted)),
                      const SizedBox(height: 12),
                      KeyValueRow('Age', '${_p!['age']}', boxed: true),
                      KeyValueRow('Gender', '${_p!['gender']}', boxed: true),
                      KeyValueRow('Mobile', '${_p!['mobile']}', boxed: true),
                      KeyValueRow('Blood group', '${_p!['blood_group']}', boxed: true),
                      SecondaryButton('Print Patient History', onPressed: _print),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Appointment & queue history',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      SelectField(
                          value: _range,
                          options: _ranges,
                          leading: Icons.date_range,
                          onChanged: (v) => setState(() => _range = v)),
                      const SizedBox(height: 12),
                      if (_filtered.isEmpty)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: Text('No visits in this period.', style: TextStyle(color: C.muted))))
                      else
                        for (final v in _filtered) _visit(v),
                    ]),
                  ),
                ]),
    );
  }

  Widget _visit(Map<String, dynamic> v) {
    final id = v['id'] as int;
    final open = _open.contains(id);
    final status = '${v['status']}'[0].toUpperCase() + '${v['status']}'.substring(1);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(longDate(v['date']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          StatusChip(status),
        ]),
        const SizedBox(height: 6),
        KeyValueRow('Clinic', '${v['clinic_name']}'),
        KeyValueRow('Doctor', '${v['doctor']}'),
        KeyValueRow('Token', '${v['token']}'),
        if (open) ...[
          KeyValueRow('Hospital', '${v['hospital']}'),
          KeyValueRow('Room', '${v['room']}'),
          KeyValueRow('Session time', '${v['start_time']}-${v['end_time']}'),
          KeyValueRow('Booked on', '${v['created_at']}'.split(' ').first),
        ],
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: C.brand,
              side: const BorderSide(color: C.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(open ? Icons.expand_less : Icons.expand_more),
            label: Text(open ? 'Hide visit details' : 'Show visit details'),
            onPressed: () => setState(() => open ? _open.remove(id) : _open.add(id)),
          ),
        ),
      ]),
    );
  }
}
