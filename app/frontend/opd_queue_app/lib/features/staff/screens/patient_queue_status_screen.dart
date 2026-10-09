import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

/// Shown to a patient (or by staff on their behalf) so they can
/// see their live token number and queue status in real-time.
/// Powered by /api/bookings — same data staff updates.
class PatientQueueStatusScreen extends StatefulWidget {
  final String patientPhone;
  final String patientName;

  const PatientQueueStatusScreen({
    super.key,
    required this.patientPhone,
    required this.patientName,
  });

  @override
  State<PatientQueueStatusScreen> createState() =>
      _PatientQueueStatusScreenState();
}

class _PatientQueueStatusScreenState
    extends State<PatientQueueStatusScreen> {
  final StaffApiService _api = StaffApiService();
  List<WalkInBooking> _bookings = [];
  List<WalkInBooking> _allActive = []; // for position in queue
  bool _isLoading = true;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _load();
    // Auto-refresh every 15 s so status updates show without manual refresh
    _autoRefresh =
        Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = _bookings.isEmpty);
    final all = await _api.getAllBookings();
    setState(() {
      _bookings = all
          .where((b) =>
              b.patientPhone.trim() == widget.patientPhone.trim() ||
              b.patientName.trim().toLowerCase() ==
                  widget.patientName.trim().toLowerCase())
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _allActive = all
          .where((b) =>
              b.status == 'entered_opd' || b.status == 'waiting_room')
          .toList();
      _isLoading = false;
    });
  }

  String _tokenFor(WalkInBooking b) {
    final raw = b.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    return 'Q-${raw.substring(raw.length > 4 ? raw.length - 4 : 0).toUpperCase()}';
  }

  /// Queue position (how many people are waiting ahead)
  int _positionFor(WalkInBooking b) {
    final idx = _allActive.indexWhere((x) => x.id == b.id);
    return idx == -1 ? 0 : idx + 1;
  }

  Color _bgColor(String status) {
    switch (status) {
      case 'in_consultation': return const Color(0xFF1E3A5F);
      case 'completed':       return const Color(0xFF1A3A2A);
      case 'absent':
      case 'cancelled':       return const Color(0xFF3A1A1A);
      default:                return const Color(0xFF1A2E4A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = _bookings.isNotEmpty ? _bookings.first : null;

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Queue Status',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: kPrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ── Today's active ticket ──────────────────────────
                    if (latest != null &&
                        latest.status != 'completed' &&
                        latest.status != 'absent' &&
                        latest.status != 'cancelled')
                      _ActiveTicketCard(
                        booking: latest,
                        token: _tokenFor(latest),
                        position: _positionFor(latest),
                        bgColor: _bgColor(latest.status),
                      )
                    else if (latest != null)
                      _CompletedCard(
                          booking: latest, token: _tokenFor(latest))
                    else
                      _NoTicketCard(name: widget.patientName),

                    const SizedBox(height: 28),

                    // ── Past visits ────────────────────────────────────
                    if (_bookings.length > 1) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Past Visits',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: kText)),
                      ),
                      const SizedBox(height: 12),
                      ..._bookings.skip(1).map((b) {
                        final c = statusColor(b.status);
                        final token = _tokenFor(b);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: kCardDecoration(),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: c.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child:
                                  Icon(statusIcon(b.status), color: c, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(token,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: kPrimary,
                                          fontSize: 13)),
                                  Text('${b.doctorName}  ·  ${b.roomNumber}',
                                      style: const TextStyle(
                                          fontSize: 12, color: kTextMuted)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: c.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(statusLabel(b.status),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: c,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ]),
                        );
                      }),
                    ],

                    // Auto-refresh notice
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.sync_rounded,
                          color: kTextMuted, size: 13),
                      const SizedBox(width: 5),
                      Text('Auto-refreshes every 15 seconds',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400)),
                    ]),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Active ticket card ────────────────────────────────────────────────────────
class _ActiveTicketCard extends StatelessWidget {
  final WalkInBooking booking;
  final String token;
  final int position;
  final Color bgColor;

  const _ActiveTicketCard({
    required this.booking,
    required this.token,
    required this.position,
    required this.bgColor,
  });

  String get _statusMessage {
    switch (booking.status) {
      case 'entered_opd':     return 'You have entered OPD. Please wait.';
      case 'waiting_room':    return 'Please proceed to the waiting room.';
      case 'in_consultation': return 'You are now with the doctor!';
      default:                return statusLabel(booking.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = statusColor(booking.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: bgColor.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: c.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(statusIcon(booking.status), color: c, size: 14),
            const SizedBox(width: 6),
            Text(statusLabel(booking.status),
                style: TextStyle(
                    color: c, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 24),

        // Token number — BIG
        Text(token,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        const SizedBox(height: 4),
        const Text('YOUR TOKEN',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),

        const SizedBox(height: 24),

        // Info row
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            _InfoRow(icon: Icons.medical_services_rounded,
                label: 'Doctor', value: booking.doctorName),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.meeting_room_rounded,
                label: 'Room', value: booking.roomNumber),
            if (booking.status == 'waiting_room' ||
                booking.status == 'entered_opd') ...[
              const SizedBox(height: 8),
              _InfoRow(
                  icon: Icons.people_rounded,
                  label: 'Position',
                  value: position == 0
                      ? 'First in line!'
                      : '#$position in queue'),
            ],
          ]),
        ),

        const SizedBox(height: 16),

        // Message
        Text(_statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13)),
      ]),
    );
  }
}

// ── Completed card ────────────────────────────────────────────────────────────
class _CompletedCard extends StatelessWidget {
  final WalkInBooking booking;
  final String token;
  const _CompletedCard({required this.booking, required this.token});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(booking.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
              color: c.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(statusIcon(booking.status), color: c, size: 30),
        ),
        const SizedBox(height: 14),
        Text(statusLabel(booking.status),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: c)),
        const SizedBox(height: 6),
        Text(token,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: kPrimary)),
        const SizedBox(height: 4),
        Text('${booking.doctorName}  ·  ${booking.roomNumber}',
            style: const TextStyle(fontSize: 13, color: kTextMuted)),
      ]),
    );
  }
}

// ── No ticket card ────────────────────────────────────────────────────────────
class _NoTicketCard extends StatelessWidget {
  final String name;
  const _NoTicketCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: kCardDecoration(),
      child: Column(children: [
        const Icon(Icons.confirmation_number_outlined,
            size: 56, color: Color(0xFFDDE2E6)),
        const SizedBox(height: 16),
        Text('No active ticket for $name',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: kText)),
        const SizedBox(height: 8),
        const Text('Please check in at the OPD reception.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kTextMuted)),
      ]),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: Colors.white54, size: 15),
        const SizedBox(width: 8),
        Text('$label:  ',
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ]);
}
