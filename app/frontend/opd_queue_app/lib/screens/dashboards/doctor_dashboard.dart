import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/doctor_service.dart';
import '../login_screen.dart';
import '../doctor/doctor_theme.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: DoctorTheme.danger, size: 22),
            SizedBox(width: 8),
            Text('End Doctor Session?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of the OPD Consultation Dashboard?',
          style: TextStyle(color: DoctorTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: DoctorTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Logout Session'),
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

    final doctorName = widget.user.name.isNotEmpty ? widget.user.name : 'Dr. RKAM Deshan';

    return Scaffold(
      backgroundColor: DoctorTheme.background,
      appBar: AppBar(
        backgroundColor: DoctorTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            // Doctor Avatar Circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Room 2 • General OPD Live',
                        style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout Session',
            onPressed: _onLogout,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: DoctorTheme.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          indicatorColor: DoctorTheme.primaryTint,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.format_list_numbered_rounded, color: DoctorTheme.textSecondary),
              selectedIcon: Icon(Icons.format_list_numbered_rounded, color: DoctorTheme.primary),
              label: 'Daily Queue',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_rounded, color: DoctorTheme.textSecondary),
              selectedIcon: Icon(Icons.edit_note_rounded, color: DoctorTheme.primary),
              label: 'Notes & Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_rounded, color: DoctorTheme.textSecondary),
              selectedIcon: Icon(Icons.insights_rounded, color: DoctorTheme.primary),
              label: 'Reports & Logs',
            ),
          ],
        ),
      ),
    );
  }
}
