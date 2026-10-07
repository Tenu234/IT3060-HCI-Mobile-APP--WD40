import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'dashboards/doctor_dashboard.dart';
import 'dashboards/nurse_dashboard.dart';
import 'dashboards/admin_dashboard.dart';
import '../features/staff/screens/staff_dashboard_screen.dart';

const _teal = Color(0xFF1A5C6B);
const _bg = Color(0xFFF0F4F5);

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _staffIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _staffIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToDashboard(UserModel user) {
    Widget dashboard;
    switch (user.role.toLowerCase()) {
      case 'doctor':
        dashboard = DoctorDashboard(user: user);
        break;
      case 'nurse':
        dashboard = NurseDashboard(user: user);
        break;
      case 'admin':
        dashboard = AdminDashboard(user: user);
        break;
      default:
        // staff / nurse role → staff dashboard
        dashboard = const StaffDashboardScreen();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
      (route) => false,
    );
  }

  Future<void> _handleLogin() async {
    if (_staffIdController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter your Staff ID and password.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = await AuthService.login(
        _staffIdController.text.trim(),
        _passwordController.text,
      );
      if (mounted) _navigateToDashboard(user);
    } catch (e) {
      setState(
          () => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back link
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back,
                            size: 18, color: _teal),
                        SizedBox(width: 6),
                        Text('Patient login',
                            style: TextStyle(
                                color: _teal,
                                fontWeight: FontWeight.w500,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Staff login',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 6),
                  const Text(
                      'For doctors and hospital administration only.',
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF6B7280))),
                  const SizedBox(height: 28),

                  // Staff ID
                  const Text('Staff ID',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  _inputBox(
                      controller: _staffIdController,
                      hint: 'e.g. DOC1024'),
                  const SizedBox(height: 6),
                  const Text('Printed on your hospital ID card.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                  const SizedBox(height: 16),

                  // Password
                  const Text('Password',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  _inputBox(
                    controller: _passwordController,
                    hint: '',
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(_error!,
                          style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5))
                          : const Text('Log in',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Demo: DOC1024 (doctor) · ADM2001 (admin) · any 6+ char password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputBox({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE2E6)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB0B8BF)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
