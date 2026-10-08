import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/staff_api_service.dart';
import '../models/walk_in_booking.dart';
import 'walk_in_booking_screen.dart';
import 'daily_register_screen.dart';
import 'live_queue_screen.dart';
import 'patient_status_update_screen.dart';

const _primary = Color(0xFF006D77);
const _surface = Color(0xFFF4F9F9);

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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _bookings = await _api.getAllBookings();
    setState(() => _isLoading = false);
  }

  int get _waiting => _bookings.where((b) => b.status == 'waiting' || b.status == 'waiting_room').length;
  int get _inRoom  => _bookings.where((b) => b.status == 'in_consultation').length;
  int get _done    => _bookings.where((b) => b.status == 'completed').length;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: _surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: _primary,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        Container(
                          height: 180,
                          decoration: const BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -30, right: -30,
                          child: Opacity(
                            opacity: 0.08,
                            child: Container(
                              width: 160, height: 160,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_greeting,
                                            style: const TextStyle(
                                                color: Colors.white70, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        const Text('OPD Staff Panel',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: _load,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
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
                                const SizedBox(height: 4),
                                Text(
                                  '${now.day}/${now.month}/${now.year}  •  ${_bookings.length} patients today',
                                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          _Stat(label: 'Waiting',  value: _waiting, color: const Color(0xFFE9943A)),
                          const SizedBox(width: 10),
                          _Stat(label: 'In Room',  value: _inRoom,  color: const Color(0xFF3A7BD5)),
                          const SizedBox(width: 10),
                          _Stat(label: 'Completed', value: _done,   color: const Color(0xFF2ECC71)),
                        ],
                      ),
                    ),
                  ),

                  // Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Actions',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 12),
                          _ActionTile(icon: Icons.person_add_alt_1_rounded, label: 'Walk-In Booking',
                              sub: 'Register a new patient', color: _primary,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalkInBookingScreen())).then((_) => _load())),
                          _ActionTile(icon: Icons.format_list_bulleted_rounded, label: 'Daily Register',
                              sub: 'All bookings for today', color: const Color(0xFF2E7D5A),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyRegisterScreen())).then((_) => _load())),
                          _ActionTile(icon: Icons.monitor_heart_rounded, label: 'Live Queue Board',
                              sub: 'Real-time patient queue', color: const Color(0xFF5B4FCF),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveQueueScreen())).then((_) => _load())),
                          _ActionTile(icon: Icons.swap_horiz_rounded, label: 'Patient Status',
                              sub: 'Update consultation stage', color: const Color(0xFFC0392B),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientStatusUpdateScreen())).then((_) => _load())),
                        ],
                      ),
                    ),
                  ),

                  // Recent patients
                  if (_bookings.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                        child: Text('Recent Patients',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E))),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _PatientRow(booking: _bookings[i]),
                          childCount: _bookings.length > 5 ? 5 : _bookings.length,
                        ),
                      ),
                    ),
                  ] else
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PatientRow extends StatelessWidget {
  final WalkInBooking booking;
  const _PatientRow({required this.booking});

  Color get _color {
    switch (booking.status) {
      case 'waiting':
      case 'waiting_room': return const Color(0xFFE9943A);
      case 'in_consultation': return const Color(0xFF3A7BD5);
      case 'completed': return const Color(0xFF2ECC71);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _color.withOpacity(0.1),
            child: Text(
              booking.patientName.isNotEmpty ? booking.patientName[0].toUpperCase() : '?',
              style: TextStyle(color: _color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.patientName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${booking.doctorName} · ${booking.roomNumber}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              booking.status.replaceAll('_', ' '),
              style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
