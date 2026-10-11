import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../features/staff/screens/staff_dashboard_screen.dart';

class NurseDashboard extends StatelessWidget {
  final UserModel user;
  const NurseDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return const StaffDashboardScreen();
  }
}
