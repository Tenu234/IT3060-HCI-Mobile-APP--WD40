import 'package:flutter/material.dart';
import '../router.dart';
import '../services/api.dart';
import '../services/auth.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_id.text.trim().isEmpty || _pw.text.isEmpty) {
      setState(() => _error = 'Enter your NIC or mobile number and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Auth.i.login(_id.text.trim(), _pw.text);
      if (Auth.i.role != 'admin') {
        await Auth.i.logout();
        if (mounted) setState(() => _error = 'This app is for OPD administrators only.');
        return;
      }
      if (!mounted) return;
      goHome(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpdAppBar(subtitle: 'OPD Admin', showBack: false),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(padding: const EdgeInsets.all(20), shrinkWrap: true, children: [
              const Heading('Admin sign in', subtitle: 'Log in to manage OPD bookings, clinics and doctors.'),
              const SizedBox(height: 20),
              Panel(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  LabeledField(
                    label: 'NIC or mobile number',
                    controller: _id,
                    hint: 'Enter NIC or +94 mobile',
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  LabeledField(label: 'Password', controller: _pw, hint: 'Enter password', password: true),
                  if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
                  const SizedBox(height: 18),
                  PrimaryButton('Log In', onPressed: _login, loading: _loading),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text('Demo admin: 198011111111 / Admin@123',
                        style: TextStyle(color: C.muted, fontSize: 12.5)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
