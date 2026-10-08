import 'package:flutter/material.dart';
import '../router.dart';
import '../services/api.dart';
import '../services/auth.dart';
import '../theme.dart';
import '../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _nic = TextEditingController();
  final _age = TextEditingController();
  final _mobile = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  String? _gender;
  bool _terms = false;
  bool _loading = false;
  String? _formError;
  Map<String, String> _err = {};

  @override
  void dispose() {
    for (final c in [_name, _nic, _age, _mobile, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  // Inline validation (mirrors the server rules) - errors appear under each field.
  Map<String, String> _validate() {
    final e = <String, String>{};
    if (_name.text.trim().length < 3) e['full_name'] = 'Enter your full name as shown on your NIC.';
    final nic = _nic.text.trim();
    if (!RegExp(r'^(\d{9}[VvXx]|\d{12})$').hasMatch(nic)) {
      e['nic'] = 'NIC must be 12 digits, or 9 digits followed by V/X.';
    }
    final age = int.tryParse(_age.text.trim());
    if (age == null || age < 0 || age > 120) e['age'] = 'Enter a valid age.';
    if (_gender == null) e['gender'] = 'Select a gender.';
    final digits = _mobile.text.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('0') ? digits.substring(1) : digits;
    if (local.length != 9) e['mobile'] = 'Enter a valid mobile, e.g. 77 123 4567.';
    if (_pw.text.length < 8) {
      e['password'] = 'Password must be at least 8 characters.';
    } else if (_pw.text != _pw2.text) {
      e['confirm_password'] = 'Passwords do not match.';
    }
    if (!_terms) e['accepted_terms'] = 'You must agree to the Terms and Privacy Notice.';
    return e;
  }

  Future<void> _submit() async {
    final e = _validate();
    setState(() {
      _err = e;
      _formError = e.isEmpty ? null : 'Please fix the highlighted fields.';
    });
    if (e.isNotEmpty) return;

    final digits = _mobile.text.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('0') ? digits.substring(1) : digits;
    setState(() => _loading = true);
    try {
      await Auth.i.register({
        'full_name': _name.text.trim(),
        'nic': _nic.text.trim(),
        'age': int.parse(_age.text.trim()),
        'gender': _gender,
        'mobile': '+94$local',
        'password': _pw.text,
        'confirm_password': _pw2.text,
        'accepted_terms': _terms,
      });
      if (!mounted) return;
      snack(context, 'Account created. Welcome!');
      goHome(context);
    } on ApiException catch (ex) {
      if (mounted) {
        setState(() {
          _err = ex.fields;
          _formError = ex.message;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpdAppBar(),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Heading('Create your account',
              subtitle: 'Register once to find clinics and manage OPD appointments.'),
          const SizedBox(height: 16),
          LabeledField(label: 'Full Name', controller: _name, hint: 'As shown on your NIC', error: _err['full_name']),
          const SizedBox(height: 14),
          LabeledField(
              label: 'NIC / National ID',
              controller: _nic,
              hint: '200012345678',
              error: _err['nic'],
              keyboard: TextInputType.text),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: LabeledField(
                  label: 'Age', controller: _age, hint: 'Age', error: _err['age'], keyboard: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectField(
                label: 'Gender',
                value: _gender,
                options: const ['Male', 'Female', 'Other'],
                error: _err['gender'],
                onChanged: (v) => setState(() => _gender = v),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          LabeledField(
              label: 'Mobile Number',
              controller: _mobile,
              hint: '77 123 4567',
              prefix: '+94',
              error: _err['mobile'],
              keyboard: TextInputType.phone),
          const SizedBox(height: 14),
          LabeledField(
              label: 'Password',
              controller: _pw,
              hint: 'Minimum 8 characters',
              password: true,
              error: _err['password']),
          const SizedBox(height: 14),
          LabeledField(
              label: 'Confirm Password',
              controller: _pw2,
              hint: 'Re-enter password',
              password: true,
              error: _err['confirm_password']),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _terms = !_terms),
            child: Row(children: [
              Checkbox(value: _terms, onChanged: (v) => setState(() => _terms = v ?? false)),
              const Expanded(child: Text('I agree to the Terms and Privacy Notice')),
            ]),
          ),
          if (_err['accepted_terms'] != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 6),
              child: Text(_err['accepted_terms']!, style: const TextStyle(color: C.red, fontSize: 13)),
            ),
          if (_formError != null) ...[const SizedBox(height: 6), ErrorBanner(_formError!)],
          const SizedBox(height: 12),
          PrimaryButton('Register', onPressed: _submit, loading: _loading),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Already registered? Log in'),
            ),
          ),
          const Center(child: Text('Fictional demo data only.', style: TextStyle(color: C.muted, fontSize: 12))),
        ]),
      ),
    );
  }
}
