import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../login_screen.dart';

class AdminDashboard extends StatelessWidget {
  final UserModel user;
  const AdminDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
        child: Text('Welcome, ${user.name}\nSystem management appears here.'),
      ),
    );
  }
}
