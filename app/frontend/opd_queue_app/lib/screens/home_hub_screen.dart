import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboards/patient_dashboard.dart';
import 'dashboards/doctor_dashboard.dart';
import 'dashboards/nurse_dashboard.dart';
import 'dashboards/admin_dashboard.dart';
import '../models/user_model.dart';
import '../features/staff/screens/staff_dashboard_screen.dart';

class HomeHubScreen extends StatelessWidget {
  const HomeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF004D56), Color(0xFF006D77), Color(0xFF00897B)],
              ),
            ),
          ),

          // Blur balls
          Positioned(top: -80, left: -60,
              child: _Ball(size: size.width * 0.6, color: Colors.white.withOpacity(0.06))),
          Positioned(bottom: -60, right: -60,
              child: _Ball(size: size.width * 0.5, color: Colors.tealAccent.withOpacity(0.07))),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        child: const Icon(Icons.local_hospital_rounded,
                            color: Color(0xFF006D77), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OPD Queue',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('Select your role to continue',
                              style: TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Role cards
                  _RoleCard(
                    icon: Icons.person_rounded,
                    title: 'Patient',
                    subtitle: 'Book appointments & view records',
                    color: const Color(0xFF2E86AB),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PatientDashboard(
                        user: UserModel(id: 'demo', name: 'Demo Patient',
                            email: 'patient@demo.com', role: 'patient', token: ''),
                      ),
                    )),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    icon: Icons.medical_services_rounded,
                    title: 'Doctor',
                    subtitle: 'Manage consultations & queue',
                    color: const Color(0xFF5B4FCF),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DoctorDashboard(
                        user: UserModel(id: 'demo', name: 'Dr. Demo',
                            email: 'doctor@demo.com', role: 'doctor', token: ''),
                      ),
                    )),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    icon: Icons.monitor_heart_rounded,
                    title: 'Staff / Nurse',
                    subtitle: 'Walk-ins, queue & patient status',
                    color: const Color(0xFF006D77),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StaffDashboardScreen())),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin',
                    subtitle: 'System management & reports',
                    color: const Color(0xFFC0392B),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AdminDashboard(
                        user: UserModel(id: 'demo', name: 'Admin Demo',
                            email: 'admin@demo.com', role: 'admin', token: ''),
                      ),
                    )),
                  ),

                  const SizedBox(height: 32),

                  // Login button
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('Sign in with your account',
                                  style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w600, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ball extends StatelessWidget {
  final double size;
  final Color color;
  const _Ball({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.title,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65), fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.5), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
