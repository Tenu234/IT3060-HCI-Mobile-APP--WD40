import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'clinic_search_screen.dart';
import 'my_appointments_screen.dart';
import 'profile_screen.dart';

class PatientShell extends StatefulWidget {
  final int initialIndex;
  const PatientShell({super.key, this.initialIndex = 0});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  late int _selectedIndex;
  int _savedRefreshKey = 0;

  List<Widget> get _tabs => [
    const ClinicSearchScreen(showAccountMenu: false),
    ClinicSearchScreen(
      savedOnly: true,
      showAccountMenu: false,
      refreshKey: _savedRefreshKey,
    ),
    const MyAppointmentsScreen(),
    const QueuePlaceholderScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex < 0
        ? 0
        : widget.initialIndex >= _tabs.length
            ? _tabs.length - 1
            : widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: C.blueSoft,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? C.brand : C.muted,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected) ? C.brand : C.muted,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() {
            _selectedIndex = index;
            if (index == 1) _savedRefreshKey++;
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.search),
              label: 'Find',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Saved',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'Appointments',
            ),
            NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(Icons.confirmation_number),
              label: 'Queue',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class QueuePlaceholderScreen extends StatelessWidget {
  const QueuePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: OpdAppBar(),
      body: Center(
        child: EmptyState(
          icon: Icons.confirmation_number_outlined,
          title: 'Queue status',
          message:
              'Your live queue position and estimated wait time will appear here after the Queue module is integrated.',
        ),
      ),
    );
  }
}
