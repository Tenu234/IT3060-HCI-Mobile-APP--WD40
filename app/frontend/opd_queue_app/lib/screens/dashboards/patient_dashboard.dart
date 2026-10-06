import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../login_screen.dart';
import '../patient/appointment_detail_screen.dart';
import '../patient/opd_search_screen.dart';
import '../patient/patient_profile_screen.dart';

class PatientDashboard extends StatefulWidget {
  final UserModel user;
  const PatientDashboard({super.key, required this.user});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  late Future<List<AppointmentModel>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _appointmentsFuture = AppointmentService.getMyAppointments();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'upcoming':   return Colors.teal;
      case 'completed':  return Colors.grey;
      case 'cancelled':  return Colors.red;
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => PatientProfileScreen(user: widget.user),
              ));
              _reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,',
                        style: TextStyle(color: Colors.white.withOpacity(0.8))),
                    const SizedBox(height: 4),
                    Text(widget.user.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Book appointment button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Book New Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => OpdSearchScreen(user: widget.user),
                    ));
                    _reload();
                  },
                ),
              ),
              const SizedBox(height: 24),

              Text('My Appointments',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Appointments list
              FutureBuilder<List<AppointmentModel>>(
                future: _appointmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final appointments = snapshot.data ?? [];
                  if (appointments.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No appointments yet.'),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: appointments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final apt = appointments[i];
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(apt.opdName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${apt.hospitalName}\n${apt.date}  •  ${apt.timeSlot}'),
                          isThreeLine: true,
                          trailing: Chip(
                            label: Text(apt.status.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 11)),
                            backgroundColor: _statusColor(apt.status),
                            padding: EdgeInsets.zero,
                          ),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => AppointmentDetailScreen(appointment: apt),
                            ));
                            _reload();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
