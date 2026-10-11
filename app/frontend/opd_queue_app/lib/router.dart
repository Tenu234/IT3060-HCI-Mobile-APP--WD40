import 'package:flutter/material.dart';
import 'screens/admin_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth.dart';

/// This app is the OPD Admin dashboard only.
Widget homeForRole(String role) => const AdminShell();

/// Replace the whole stack with the admin dashboard.
void goHome(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => homeForRole(Auth.i.role)),
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
