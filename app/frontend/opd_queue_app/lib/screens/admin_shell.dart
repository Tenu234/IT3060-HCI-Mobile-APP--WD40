import 'package:flutter/material.dart';
import '../theme.dart';
import 'admin_bookings_screen.dart';
import 'admin_clinics_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_sessions_screen.dart';
import 'admin_patients_screen.dart';

/// OPD Clinic Admin dashboard: 5 bottom tabs.
class AdminShell extends StatefulWidget {
  final int initialIndex;
  const AdminShell({super.key, this.initialIndex = 0});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _index = widget.initialIndex;

  static const _tabs = <_Tab>[
    _Tab('Bookings', Icons.event_note_outlined, Icons.event_note),
    _Tab('Clinics', Icons.local_hospital_outlined, Icons.local_hospital),
    _Tab('Doctors', Icons.medical_services_outlined, Icons.medical_services),
    _Tab('Sessions', Icons.schedule_outlined, Icons.schedule),
    _Tab('Patients', Icons.person_search_outlined, Icons.person_search),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: const [
        AdminBookingsScreen(),
        AdminClinicsScreen(),
        AdminDoctorsScreen(),
        AdminSessionsScreen(),
        AdminPatientsScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: C.blueSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon, color: C.muted),
              selectedIcon: Icon(t.selectedIcon, color: C.brand),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _Tab(this.label, this.icon, this.selectedIcon);
}
