import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/doctor_service.dart';
import '../login_screen.dart';
import '../doctor/doctor_queue_screen.dart';
import '../doctor/consultation_notes_and_dispatch_screen.dart';
import '../doctor/doctor_reports_screen.dart';

class DoctorDashboard extends StatefulWidget {
  final UserModel user;
  const DoctorDashboard({super.key, required this.user});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    DoctorService.setToken(widget.user.token);
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to end your consultation session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DoctorQueueScreen(onQueueUpdated: () => setState(() {})),
      const ConsultationNotesAndDispatchScreen(),
      const DoctorReportsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.user.name.isNotEmpty ? widget.user.name : 'Dr. RKAM Deshan',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'Clinical Medical Officer • Room 2',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: Colors.teal.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.format_list_numbered),
            selectedIcon: Icon(Icons.format_list_numbered, color: Colors.teal),
            label: 'Daily Queue (FR06)',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note),
            selectedIcon: Icon(Icons.edit_note, color: Colors.teal),
            label: 'Notes & Alerts (FR09)',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights),
            selectedIcon: Icon(Icons.insights, color: Colors.teal),
            label: 'Reports & Logs (FR15)',
          ),
        ],
      ),
    );
  }
}
