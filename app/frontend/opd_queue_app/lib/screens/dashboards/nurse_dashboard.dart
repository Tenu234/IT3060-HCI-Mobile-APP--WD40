import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../login_screen.dart';

class NurseDashboard extends StatelessWidget {
  final UserModel user;
  const NurseDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nurse Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome, ${user.name}\nPatient management appears here.'),
      ),
    );
  }
}
