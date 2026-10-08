import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'dashboards/patient_dashboard.dart';
import 'dashboards/doctor_dashboard.dart';
import 'dashboards/nurse_dashboard.dart';
import 'dashboards/admin_dashboard.dart';
import 'register_screen.dart';
import '../features/staff/screens/staff_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  bool _loading         = false;
  bool _hidePass        = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.login(
        _emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) _go(user);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _go(UserModel user) {
    Widget dash;
    switch (user.role.toLowerCase()) {
      case 'doctor': dash = DoctorDashboard(user: user); break;
      case 'nurse':  dash = NurseDashboard(user: user);  break;
      case 'admin':  dash = AdminDashboard(user: user);  break;
      default:       dash = PatientDashboard(user: user);
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => dash));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header banner ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                decoration: const BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68, height: 68,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.local_hospital_rounded,
                          color: kPrimary, size: 34),
                    ),
                    const SizedBox(height: 16),
                    const Text('OPD Queue',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Sign in to your account',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13)),
                  ],
                ),
              ),

              // ── Form ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email', style: kLabelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: kInputDecoration(
                            label: 'Enter your email',
                            icon: Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      const Text('Password', style: kLabelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _hidePass,
                        decoration: kInputDecoration(
                          label: 'Enter your password',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            icon: Icon(
                              _hidePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: kTextMuted, size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _hidePass = !_hidePass),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),

                      // Error banner
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kCancelled.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: kCancelled.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: kCancelled, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(
                                        color: kCancelled, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Text('Sign In',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Register row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ",
                              style: TextStyle(
                                  color: kTextMuted, fontSize: 13)),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const RegisterScreen())),
                            child: const Text('Register',
                                style: TextStyle(
                                    color: kPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12)),
                        ),
                        const Expanded(child: Divider()),
                      ]),

                      const SizedBox(height: 20),

                      // Staff quick-access
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.badge_outlined,
                              color: kPrimary, size: 20),
                          label: const Text('Staff / Nurse Access',
                              style: TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: kPrimary, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const StaffDashboardScreen())),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
