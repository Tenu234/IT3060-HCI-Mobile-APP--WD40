import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../services/staff_api_service.dart';
import '../models/walk_in_booking.dart';
import 'walk_in_booking_screen.dart';
import 'daily_register_screen.dart';
import 'live_queue_screen.dart';
import 'patient_status_update_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});
  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
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
    _bookings = await _api.getAllBookings();
    setState(() => _isLoading = false);
  }

  int get _waiting  => _bookings.where((b) => b.status == 'waiting' || b.status == 'waiting_room' || b.status == 'entered_opd').length;
  int get _inRoom   => _bookings.where((b) => b.status == 'in_consultation').length;
  int get _done     => _bookings.where((b) => b.status == 'completed').length;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateLabel {
    final n = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[n.weekday - 1]}, ${n.day} ${months[n.month - 1]} ${n.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  // ── Top header ──────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildHeader()),

                  // ── Stats row ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(children: [
                        _StatCard(label: 'Waiting',   value: _waiting, color: kWaiting, icon: Icons.hourglass_top_rounded),
                        const SizedBox(width: 10),
                        _StatCard(label: 'In Room',   value: _inRoom,  color: kActive,  icon: Icons.medical_services_rounded),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Completed', value: _done,    color: kDone,    icon: Icons.check_circle_rounded),
                      ]),
                    ),
                  ),

                  // ── Quick actions ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quick Actions',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kText)),
                          const SizedBox(height: 14),
                          // 2×2 grid of action cards
                          Row(children: [
                            _ActionCard(
                              icon: Icons.person_add_alt_1_rounded,
                              label: 'New Walk-In',
                              color: kPrimary,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const WalkInBookingScreen()))
                                  .then((_) => _load()),
                            ),
                            const SizedBox(width: 12),
                            _ActionCard(
                              icon: Icons.monitor_heart_rounded,
                              label: 'Live Queue',
                              color: const Color(0xFF5B4FCF),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const LiveQueueScreen()))
                                  .then((_) => _load()),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _ActionCard(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Update Status',
                              color: const Color(0xFFE67E22),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const PatientStatusUpdateScreen()))
                                  .then((_) => _load()),
                            ),
                            const SizedBox(width: 12),
                            _ActionCard(
                              icon: Icons.format_list_bulleted_rounded,
                              label: 'Daily Register',
                              color: const Color(0xFF2E7D5A),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const DailyRegisterScreen()))
                                  .then((_) => _load()),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),

                  // ── Recent patients ──────────────────────────────────────
                  if (_bookings.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                        child: Text('Recent Patients',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kText)),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _RecentPatientTile(booking: _bookings[i]),
                          childCount: _bookings.length > 5 ? 5 : _bookings.length,
                        ),
                      ),
                    ),
                  ] else
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Avatar + greeting
                      Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_greeting,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 13)),
                            const Text('NHSL Staff Portal',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ]),
                      // Refresh
                      GestureDetector(
                        onTap: _load,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Colors.white54, size: 13),
                    const SizedBox(width: 5),
                    Text(_dateLabel,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 14),
                    const Icon(Icons.people_rounded,
                        color: Colors.white54, size: 13),
                    const SizedBox(width: 5),
                    Text('${_bookings.length} patients today',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: kCardDecoration(),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text('$value',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: kTextMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Action card (2-col grid) ─────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: kCardDecoration(),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kText)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Recent patient tile ──────────────────────────────────────────────────────
class _RecentPatientTile extends StatelessWidget {
  final WalkInBooking booking;
  const _RecentPatientTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(booking.status);
    final initial = booking.patientName.isNotEmpty
        ? booking.patientName[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: kCardDecoration(),
      child: Row(children: [
        // Token / avatar
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: c.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(initial,
                style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.patientName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: kText)),
              const SizedBox(height: 2),
              Text('${booking.doctorName}  ·  ${booking.roomNumber}',
                  style: const TextStyle(fontSize: 12, color: kTextMuted)),
            ],
          ),
        ),
        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(statusLabel(booking.status),
              style: TextStyle(
                  fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
