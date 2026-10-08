import 'package:flutter/material.dart';
import 'router.dart';
import 'screens/login_screen.dart';
import 'services/auth.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OpdApp());
}

class OpdApp extends StatelessWidget {
  const OpdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Government Hospital OPD',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _Boot(),
    );
  }
}

/// Restores a saved session (if any) and opens the right home screen.
class _Boot extends StatefulWidget {
  const _Boot();
  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Auth.i.restore();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => Auth.i.loggedIn ? homeForRole(Auth.i.role) : const LoginScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
