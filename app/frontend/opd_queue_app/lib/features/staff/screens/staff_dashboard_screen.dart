import 'package:flutter/material.dart';
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
  final StaffApiService _apiService = StaffApiService();
  List<WalkInBooking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final bookings = await _apiService.getAllBookings();
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  int get _waitingCount =>
      _bookings.where((b) => b.status == 'waiting').length;
  int get _inConsultationCount =>
      _bookings.where((b) => b.status == 'in_consultation').length;
  int get _completedCount =>
      _bookings.where((b) => b.status == 'completed').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Staff Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Text(
                      'Today — ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: const TextStyle(
                          fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Queue summary cards
                    const Text('Queue Summary',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _SummaryCard(
                          label: 'Waiting',
                          count: _waitingCount,
                          color: Colors.orange,
                          icon: Icons.hourglass_empty,
                        ),
                        const SizedBox(width: 12),
                        _SummaryCard(
                          label: 'In Consultation',
                          count: _inConsultationCount,
                          color: Colors.blue,
                          icon: Icons.medical_services,
                        ),
                        const SizedBox(width: 12),
                        _SummaryCard(
                          label: 'Completed',
                          count: _completedCount,
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick actions
                    const Text('Quick Actions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.person_add,
                      label: 'New Walk-In Booking',
                      subtitle: 'Register a patient at the OPD desk',
                      color: const Color(0xFF1565C0),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WalkInBookingScreen()),
                      ).then((_) => _loadBookings()),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.list_alt,
                      label: 'Daily Patient Register',
                      subtitle: 'View and manage all bookings today',
                      color: const Color(0xFF00897B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DailyRegisterScreen()),
                      ).then((_) => _loadBookings()),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.view_list,
                      label: 'Live Queue Board',
                      subtitle: 'Monitor real-time queue across rooms',
                      color: const Color(0xFF6A1B9A),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LiveQueueScreen()),
                      ).then((_) => _loadBookings()),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.update,
                      label: 'Patient Turn Status',
                      subtitle: 'Update patient status through consultation stages',
                      color: const Color(0xFFC62828),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PatientStatusUpdateScreen()),
                      ).then((_) => _loadBookings()),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200, blurRadius: 4, spreadRadius: 1)
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text('$count',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
