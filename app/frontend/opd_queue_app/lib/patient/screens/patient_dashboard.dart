import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import '../../screens/login_screen.dart';
import 'appointment_detail_screen.dart';
import 'opd_search_screen.dart';
import 'patient_profile_screen.dart';
import 'lab_reports_screen.dart';

class PatientDashboard extends StatefulWidget {
  final UserModel user;
  const PatientDashboard({super.key, required this.user});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard>
    with SingleTickerProviderStateMixin {
  late Future<List<AppointmentModel>> _appointmentsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _appointmentsFuture = AppointmentService.getMyAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: const Icon(Icons.menu),
        title: const Text('My Appointments',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Staff access button (visible only for staff accounts)
          if (widget.user.email == 'tharumendis698@gmail.com')
            IconButton(
              icon: const Icon(Icons.dashboard_customize),
              tooltip: 'Staff Dashboard',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StaffDashboardScreen())),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PatientProfileScreen(user: widget.user)),
              );
              _reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Lab Reports',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LabReportsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
        ],
      ),
      body: FutureBuilder<List<AppointmentModel>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Could not load appointments.'),
                  TextButton(onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            );
          }

          final all = snapshot.data ?? [];
          final upcoming = all
              .where((a) => a.status == 'upcoming')
              .toList();
          final past = all
              .where((a) =>
                  a.status == 'completed' || a.status == 'cancelled')
              .toList();

          return Column(
            children: [
              // Tab bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    labelColor: const Color(0xFF1565C0),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'Upcoming (${upcoming.length})'),
                      Tab(text: 'Past Visits (${past.length})'),
                    ],
                  ),
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(upcoming, isUpcoming: true),
                    _buildList(past, isUpcoming: false),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // New Appointment button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('New Appointment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OpdSearchScreen(user: widget.user)),
              );
              _reload();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<AppointmentModel> appointments,
      {required bool isUpcoming}) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          isUpcoming
              ? 'No upcoming appointments.'
              : 'No past visits yet.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: appointments.length,
      itemBuilder: (context, i) {
        final apt = appointments[i];
        return _appointmentCard(apt, isUpcoming: isUpcoming, index: i);
      },
    );
  }

  Widget _appointmentCard(AppointmentModel apt,
      {required bool isUpcoming, required int index}) {
    final queueNo = 20 + index * 5;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUpcoming
                        ? const Color(0xFF1565C0)
                        : Colors.grey.shade400,
                    border: Border.all(
                        color: isUpcoming
                            ? const Color(0xFFBBDEFB)
                            : Colors.grey.shade300,
                        width: 3),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date + status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(apt.date,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      _statusBadge(apt.status),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // OPD name
                  Text(apt.opdName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),

                  // Hospital
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(apt.hospitalName,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),

                  // Queue info (upcoming only)
                  if (isUpcoming) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time,
                              size: 15, color: Color(0xFFFF8F00)),
                          const SizedBox(width: 6),
                          Text(
                            'Queue No: $queueNo  •  ${apt.timeSlot}',
                            style: const TextStyle(
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Buttons
                  SizedBox(
                    width: 140,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AppointmentDetailScreen(appointment: apt),
                          ),
                        );
                        _reload();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),

                  if (isUpcoming) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 140,
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Queue tracking coming soon.')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1565C0),
                          side: const BorderSide(color: Color(0xFF1565C0)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Track Queue'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'upcoming':
        color = Colors.green;
        label = 'CONFIRMED';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'CANCELLED';
        break;
      default:
        color = Colors.grey;
        label = 'COMPLETED';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3)),
    );
  }
}
