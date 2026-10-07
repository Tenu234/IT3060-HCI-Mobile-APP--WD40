import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'dashboards/patient_dashboard.dart';
import 'dashboards/doctor_dashboard.dart';
import 'dashboards/nurse_dashboard.dart';
import 'dashboards/admin_dashboard.dart';
import 'register_screen.dart';
import 'staff_login_screen.dart';

const _teal = Color(0xFF1A5C6B);
const _bg = Color(0xFFF0F4F5);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mobile OTP
  final _mobileController = TextEditingController();
  bool _otpSent = false;
  final _otpController = TextEditingController();

  // Patient ID
  final _patientIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _patientIdController.dispose();
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
        dashboard = PatientDashboard(user: user);
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
      (route) => false,
    );
  }

  Future<void> _handleLogin() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = await AuthService.login(
        _patientIdController.text.trim(),
        _passwordController.text,
      );
      if (mounted) _navigateToDashboard(user);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Log in to OPD portal',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 6),
                  const Text(
                      'Book tokens, view prescriptions and lab reports.',
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF6B7280))),
                  const SizedBox(height: 24),

                  // Underline tab bar
                  TabBar(
                    controller: _tabController,
                    labelColor: _teal,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontSize: 14),
                    indicatorColor: _teal,
                    indicatorWeight: 2.5,
                    dividerColor: const Color(0xFFDDE2E6),
                    tabs: const [
                      Tab(text: 'Mobile OTP'),
                      Tab(text: 'Patient ID & password'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tab content (fixed height to avoid nested scroll issues)
                  [_buildOtpTab(), _buildPatientIdTab()]
                      [_tabController.index],

                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFDDE2E6)),
                  const SizedBox(height: 16),

                  // Register link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      child: RichText(
                        text: const TextSpan(
                          text: 'First visit to this hospital? ',
                          style: TextStyle(
                              color: Color(0xFF6B7280), fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Register as a patient',
                              style: TextStyle(
                                  color: _teal,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Staff login link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const StaffLoginScreen())),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Hospital staff? ',
                          style: TextStyle(
                              color: Color(0xFF6B7280), fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Log in here →',
                              style: TextStyle(
                                  color: _teal,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildOtpTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mobile number',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        _PhoneField(controller: _mobileController),
        const SizedBox(height: 6),
        const Text('Use the number you registered with.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        if (_otpSent) ...[
          const SizedBox(height: 16),
          const Text('Enter OTP',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          _InputBox(
              controller: _otpController,
              hint: '6-digit OTP',
              keyboardType: TextInputType.number),
        ],
        const SizedBox(height: 20),
        _PrimaryButton(
          label: _otpSent ? 'Verify OTP' : 'Send OTP',
          isLoading: _isLoading,
          onPressed: () {
            if (!_otpSent) {
              setState(() {
                _otpSent = true;
                _otpController.text = '123456'; // mock OTP for testing
              });
            }
          },
        ),
        if (_otpSent) ...[
          const SizedBox(height: 8),
          const Text('Demo: OTP auto-filled as 123456',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ],
      ],
    );
  }

  Widget _buildPatientIdTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Patient ID or ABHA number',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        _InputBox(controller: _patientIdController, hint: 'OPD-2026-48213'),
        const SizedBox(height: 16),
        const Text('Password',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        _InputBox(
          controller: _passwordController,
          hint: '',
          obscure: _obscure,
          suffix: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {},
          child: const Text('Forgot password?',
              style: TextStyle(
                  color: _teal, fontWeight: FontWeight.w500, fontSize: 13)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _error!),
        ],
        const SizedBox(height: 20),
        _PrimaryButton(
            label: 'Log in', isLoading: _isLoading, onPressed: _handleLogin),
      ],
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffix;

  const _InputBox({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE2E6)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
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

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE2E6)),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFFDDE2E6))),
            ),
            child: const Text('+94',
                style:
                    TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '77 123 4567',
                hintStyle: TextStyle(color: Color(0xFFB0B8BF)),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _PrimaryButton(
      {required this.label,
      required this.isLoading,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message,
          style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
    );
  }
}
