import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

// Top-level constant so both screen and widget can access it
const _kFlow = [
  {'value': 'entered_opd',     'label': 'Entered',    'icon': Icons.login_rounded,            'color': kWaiting},
  {'value': 'waiting_room',    'label': 'Waiting',    'icon': Icons.hourglass_top_rounded,    'color': Color(0xFFF59E0B)},
  {'value': 'in_consultation', 'label': 'Consulting', 'icon': Icons.medical_services_rounded, 'color': kActive},
  {'value': 'completed',       'label': 'Completed',  'icon': Icons.check_circle_rounded,     'color': kDone},
];

class PatientStatusUpdateScreen extends StatefulWidget {
  const PatientStatusUpdateScreen({super.key});
  @override
  State<PatientStatusUpdateScreen> createState() =>
      _PatientStatusUpdateScreenState();
}

class _PatientStatusUpdateScreenState
    extends State<PatientStatusUpdateScreen> {
  final StaffApiService _api = StaffApiService();
  List<WalkInBooking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _api.getAllBookings();
    setState(() {
      _bookings = all
          .where((b) => b.status != 'cancelled' && b.status != 'absent')
          .toList();
      _isLoading = false;
    });
  }

  int _idx(String s) => _kFlow.indexWhere((f) => f['value'] == s);

  String _tokenFor(WalkInBooking b) {
    final raw = b.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    return 'Q-${raw.substring(raw.length > 4 ? raw.length - 4 : 0).toUpperCase()}';
  }

  Future<void> _advance(WalkInBooking b) async {
    final i = _idx(b.status);
    if (i < _kFlow.length - 1 && b.id != null) {
      final next = _kFlow[i + 1]['value'] as String;
      await _api.updateBooking(b.id!, {'status': next});
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${b.patientName} moved to ${statusLabel(next)}'),
        backgroundColor: kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _markAbsent(WalkInBooking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mark as Absent'),
        content: Text('Mark ${b.patientName} (${_tokenFor(b)}) as absent?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kCancelled, foregroundColor: Colors.white),
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
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Update Turn Status',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Column(children: [
              // ── Flow steps header ──────────────────────────────────────
              _FlowStepsBar(),
              // ── List ──────────────────────────────────────────────────
              Expanded(
                child: _bookings.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: kPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _bookings.length,
                          itemBuilder: (_, i) => _PatientCard(
                            booking: _bookings[i],
                            idx: _idx(_bookings[i].status),
                            token: _tokenFor(_bookings[i]),
                            onAdvance: () => _advance(_bookings[i]),
                            onAbsent: () => _markAbsent(_bookings[i]),
                          ),
                        ),
                      ),
              ),
            ]),
    );
  }
}

// ── Flow steps bar ────────────────────────────────────────────────────────────
class _FlowStepsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: List.generate(_kFlow.length * 2 - 1, (i) {
          if (i.isOdd) {
            return const Expanded(
              child: Divider(color: Color(0xFFE5E7EB), thickness: 1.5),
            );
          }
          final s = _kFlow[i ~/ 2];
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: (s['color'] as Color).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(s['icon'] as IconData,
                  color: s['color'] as Color, size: 18),
            ),
            const SizedBox(height: 4),
            Text(s['label'] as String,
                style: const TextStyle(fontSize: 10, color: kTextMuted,
                    fontWeight: FontWeight.w500)),
          ]);
        }),
      ),
    );
  }
}

// ── Patient card ──────────────────────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final WalkInBooking booking;
  final int idx;
  final String token;
  final VoidCallback onAdvance;
  final VoidCallback onAbsent;

  const _PatientCard({
    required this.booking,
    required this.idx,
    required this.token,
    required this.onAdvance,
    required this.onAbsent,
  });

  @override
  Widget build(BuildContext context) {
    final c = idx >= 0 ? _kFlow[idx]['color'] as Color : kTextMuted;
    final canAdvance = idx >= 0 && idx < _kFlow.length - 1;
    final initial = booking.patientName.isNotEmpty
        ? booking.patientName[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: kCardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ─────────────────────────────────────────────────
        Row(children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(initial,
                  style: TextStyle(
                      color: c,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(booking.patientName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: kText)),
              const SizedBox(height: 2),
              Text('${booking.doctorName}  ·  ${booking.roomNumber}',
                  style: const TextStyle(fontSize: 12, color: kTextMuted)),
            ]),
          ),
          // Token + status chip column
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(token,
                  style: const TextStyle(
                      fontSize: 11,
                      color: kPrimary,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(statusLabel(booking.status),
                  style: TextStyle(
                      fontSize: 11,
                      color: c,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ]),

        const SizedBox(height: 14),

        // ── Progress bar ───────────────────────────────────────────────
        Row(children: List.generate(_kFlow.length, (j) => Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: j < _kFlow.length - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: j <= idx
                  ? (_kFlow[j]['color'] as Color)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ))),

        const SizedBox(height: 14),

        // ── Action buttons ─────────────────────────────────────────────
        Row(children: [
          if (canAdvance) ...[
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  'Move to ${_kFlow[idx + 1]['label']}',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onAdvance,
              ),
            ),
            const SizedBox(width: 10),
          ],
          OutlinedButton.icon(
            icon: const Icon(Icons.person_off_rounded,
                size: 16, color: kCancelled),
            label: const Text('Absent',
                style: TextStyle(color: kCancelled, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kCancelled),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 14),
            ),
            onPressed: onAbsent,
          ),
        ]),
      ]),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.people_rounded, size: 64, color: Color(0xFFDDE2E6)),
          SizedBox(height: 14),
          Text('No active patients',
              style: TextStyle(color: kTextMuted, fontSize: 15)),
        ]),
      );
}
