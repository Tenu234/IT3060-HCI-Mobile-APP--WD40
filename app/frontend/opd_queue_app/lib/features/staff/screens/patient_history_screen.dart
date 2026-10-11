import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

class PatientHistoryScreen extends StatefulWidget {
  final WalkInBooking booking;
  const PatientHistoryScreen({super.key, required this.booking});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  final StaffApiService _api = StaffApiService();
  List<WalkInBooking> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _api.getAllBookings();
    // Match by phone number OR exact name (case-insensitive)
    final phone = widget.booking.patientPhone.trim();
    final name  = widget.booking.patientName.trim().toLowerCase();
    setState(() {
      _history = all.where((b) {
        final samePhone = phone.isNotEmpty && b.patientPhone.trim() == phone;
        final sameName  = b.patientName.trim().toLowerCase() == name;
        return samePhone || sameName;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
      _isLoading = false;
    });
  }

  String _tokenFor(WalkInBooking b) {
    final raw = b.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    return 'Q-${raw.substring(raw.length > 4 ? raw.length - 4 : 0).toUpperCase()}';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ·  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final initial = b.patientName.isNotEmpty
        ? b.patientName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Patient History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : CustomScrollView(
              slivers: [
                // ── Patient info card ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: kPrimary,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        // Avatar
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(initial,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.patientName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              if (b.patientPhone.isNotEmpty)
                                Row(children: [
                                  const Icon(Icons.phone_rounded,
                                      color: Colors.white60, size: 13),
                                  const SizedBox(width: 5),
                                  Text(b.patientPhone,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                ]),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_history.length} visit${_history.length != 1 ? 's' : ''} total',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),

                // ── Summary stats ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(children: [
                      _HistoryStat(
                        label: 'Completed',
                        value: '${_history.where((h) => h.status == 'completed').length}',
                        color: kDone,
                        icon: Icons.check_circle_rounded,
                      ),
                      const SizedBox(width: 10),
                      _HistoryStat(
                        label: 'Cancelled',
                        value: '${_history.where((h) => h.status == 'cancelled').length}',
                        color: kCancelled,
                        icon: Icons.cancel_rounded,
                      ),
                      const SizedBox(width: 10),
                      _HistoryStat(
                        label: 'No-Show',
                        value: '${_history.where((h) => h.status == 'absent').length}',
                        color: kTextMuted,
                        icon: Icons.person_off_rounded,
                      ),
                    ]),
                  ),
                ),

                // ── History label ──────────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Text('Visit History',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kText)),
                  ),
                ),

                // ── History list ───────────────────────────────────────────
                _history.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded,
                                  size: 56, color: Color(0xFFDDE2E6)),
                              SizedBox(height: 12),
                              Text('No previous visits found',
                                  style: TextStyle(
                                      color: kTextMuted, fontSize: 15)),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final visit = _history[i];
                              final c     = statusColor(visit.status);
                              final token = _tokenFor(visit);
                              final isCurrentVisit =
                                  visit.id == widget.booking.id;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isCurrentVisit
                                      ? Border.all(color: kPrimary, width: 1.5)
                                      : null,
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color(0x0D000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Row 1: token + current badge + status
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: kPrimary.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(token,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: kPrimary,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                        if (isCurrentVisit) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: kPrimary.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text('Current Visit',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: kPrimary,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        ],
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: c.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(statusIcon(visit.status),
                                                    color: c, size: 12),
                                                const SizedBox(width: 4),
                                                Text(statusLabel(visit.status),
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: c,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ]),
                                        ),
                                      ]),
                                      const SizedBox(height: 12),
                                      // Row 2: doctor + room
                                      Row(children: [
                                        const Icon(
                                            Icons.medical_services_rounded,
                                            color: kPrimary, size: 15),
                                        const SizedBox(width: 6),
                                        Text(visit.doctorName,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: kText)),
                                        const SizedBox(width: 12),
                                        const Icon(
                                            Icons.meeting_room_rounded,
                                            color: kTextMuted, size: 15),
                                        const SizedBox(width: 4),
                                        Text(visit.roomNumber,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: kTextMuted)),
                                      ]),
                                      const SizedBox(height: 6),
                                      // Row 3: date
                                      Row(children: [
                                        const Icon(
                                            Icons.access_time_rounded,
                                            color: kTextMuted, size: 14),
                                        const SizedBox(width: 5),
                                        Text(_formatDate(visit.createdAt),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: kTextMuted)),
                                      ]),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _history.length,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}

// ── History stat card ─────────────────────────────────────────────────────────
class _HistoryStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _HistoryStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: kTextMuted)),
        ]),
      ),
    );
  }
}
