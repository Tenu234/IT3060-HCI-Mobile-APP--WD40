import 'package:flutter/material.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

const _primary = Color(0xFF006D77);

class PatientStatusUpdateScreen extends StatefulWidget {
  const PatientStatusUpdateScreen({super.key});
  @override
  State<PatientStatusUpdateScreen> createState() => _PatientStatusUpdateScreenState();
}

class _PatientStatusUpdateScreenState extends State<PatientStatusUpdateScreen> {
  final StaffApiService _api = StaffApiService();
  List<WalkInBooking> _bookings = [];
  bool _isLoading = true;

  final _flow = [
    {'value': 'entered_opd',     'label': 'Entered',      'icon': Icons.login_rounded,            'color': const Color(0xFF006D77)},
    {'value': 'waiting_room',    'label': 'Waiting',      'icon': Icons.hourglass_empty_rounded,  'color': const Color(0xFFE9943A)},
    {'value': 'in_consultation', 'label': 'Consulting',   'icon': Icons.medical_services_rounded, 'color': const Color(0xFF3A7BD5)},
    {'value': 'completed',       'label': 'Completed',    'icon': Icons.check_circle_rounded,     'color': const Color(0xFF2ECC71)},
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _api.getAllBookings();
    setState(() {
      _bookings = all.where((b) => b.status != 'cancelled' && b.status != 'absent').toList();
      _isLoading = false;
    });
  }

  int _idx(String s) => _flow.indexWhere((f) => f['value'] == s);

  Future<void> _advance(WalkInBooking b) async {
    final i = _idx(b.status);
    if (i < _flow.length - 1 && b.id != null) {
      final next = _flow[i + 1]['value'] as String;
      await _api.updateBooking(b.id!, {'status': next});
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${b.patientName} → ${next.replaceAll('_', ' ')}'),
        backgroundColor: _primary,
      ));
    }
  }

  Future<void> _absent(WalkInBooking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark Absent'),
        content: Text('Mark ${b.patientName} as absent?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Absent'),
          ),
        ],
      ),
    );
    if (ok == true && b.id != null) {
      await _api.updateBooking(b.id!, {'status': 'absent'});
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Patient Status', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                // Flow bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: List.generate(_flow.length * 2 - 1, (i) {
                      if (i.isOdd) {
                        return const Expanded(
                          child: Divider(color: Color(0xFFDDE2E6), thickness: 1.5),
                        );
                      }
                      final s = _flow[i ~/ 2];
                      return Column(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: (s['color'] as Color).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(s['label'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      );
                    }),
                  ),
                ),

                Expanded(
                  child: _bookings.isEmpty
                      ? Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.people_rounded, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No active patients', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: _primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _bookings.length,
                            itemBuilder: (_, i) {
                              final b = _bookings[i];
                              final idx = _idx(b.status);
                              final flowEntry = idx >= 0 ? _flow[idx] : null;
                              final c = flowEntry != null ? flowEntry['color'] as Color : Colors.grey;
                              final canAdvance = idx >= 0 && idx < _flow.length - 1;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: c.withOpacity(0.1),
                                          child: Text(
                                            b.patientName.isNotEmpty ? b.patientName[0].toUpperCase() : '?',
                                            style: TextStyle(color: c, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(b.patientName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                              Text('${b.doctorName}  ·  ${b.roomNumber}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: c.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20)),
                                          child: Text(b.status.replaceAll('_', ' '),
                                              style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Progress bar
                                    Row(
                                      children: List.generate(_flow.length, (j) => Expanded(
                                        child: Container(
                                          height: 5,
                                          margin: EdgeInsets.only(right: j < _flow.length - 1 ? 4 : 0),
                                          decoration: BoxDecoration(
                                            color: j <= idx
                                                ? (_flow[j]['color'] as Color)
                                                : const Color(0xFFEEEEEE),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      )),
                                    ),
                                    const SizedBox(height: 14),

                                    Row(
                                      children: [
                                        if (canAdvance)
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                              label: Text(
                                                'Move to ${_flow[idx + 1]['label']}',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _primary,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              onPressed: () => _advance(b),
                                            ),
                                          ),
                                        if (canAdvance) const SizedBox(width: 10),
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.person_off_rounded, size: 16, color: Colors.red),
                                          label: const Text('Absent', style: TextStyle(color: Colors.red, fontSize: 13)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.red),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                          ),
                                          onPressed: () => _absent(b),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
