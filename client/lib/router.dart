import 'package:flutter/material.dart';
import 'screens/admin_sessions_screen.dart';
import 'screens/clinic_search_screen.dart';
import 'screens/login_screen.dart';
import 'screens/patient_shell.dart';
import 'screens/staff_patient_search_screen.dart';
import 'services/auth.dart';

Widget homeForRole(String role) {
  switch (role) {
    case 'admin':
      return const AdminSessionsScreen();
    case 'staff':
      return const StaffPatientSearchScreen();
    case 'patient':
      return const PatientShell();
    default:
      return const ClinicSearchScreen();
  }
}

/// Replace the whole stack with the role's home screen.
void goHome(BuildContext context, {int? tab}) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => Auth.i.role == 'patient' && tab != null
          ? PatientShell(initialIndex: tab)
          : homeForRole(Auth.i.role),
    ),
    (r) => false,
  );
}

Future<void> doLogout(BuildContext context) async {
  await Auth.i.logout();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (r) => false,
  );
}
