import 'package:flutter/material.dart';
import '../router.dart';
import '../services/api.dart';
import '../services/auth.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Patient profile: Read, Update (details + password) and Delete account.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _mobile;
  String? _gender;
  bool _edit = false;
  bool _saving = false;
  String? _error;
  Map<String, String> _err = {};

  Map<String, dynamic> get _u => Auth.i.user ?? {};

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _age = TextEditingController();
    _mobile = TextEditingController();
    _fill();
  }

  void _fill() {
    _name.text = '${_u['full_name'] ?? ''}';
    _age.text = '${_u['age'] ?? ''}';
    _mobile.text = '${_u['mobile'] ?? ''}';
    _gender = _u['gender']?.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _err = {};
    });
    try {
      final r = await Api.i.put('/auth/me', {
        'full_name': _name.text.trim(),
        'age': int.tryParse(_age.text.trim()) ?? -1,
        'gender': _gender,
        'mobile': _mobile.text.trim(),
      });
      Auth.i.updateUser(Map<String, dynamic>.from(r['user'] as Map));
      if (!mounted) return;
      setState(() => _edit = false);
      _fill();
      snack(context, 'Profile updated');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _err = e.fields;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final cur = TextEditingController();
    final next = TextEditingController();
    String? err;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Change password'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            LabeledField(label: 'Current password', controller: cur, password: true),
            const SizedBox(height: 12),
            LabeledField(label: 'New password', controller: next, password: true, hint: 'Minimum 8 characters'),
            if (err != null) ...[const SizedBox(height: 10), ErrorBanner(err!)],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                try {
                  await Api.i.put('/auth/me/password', {'current_password': cur.text, 'new_password': next.text});
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) snack(context, 'Password changed');
                } on ApiException catch (e) {
                  setS(() => err = e.message);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    cur.dispose();
    next.dispose();
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context,
        title: 'Delete account?',
        message: 'This permanently deletes your account and appointment history. This cannot be undone.',
        confirm: 'Delete',
        danger: true);
    if (!ok) return;
    try {
      await Api.i.delete('/auth/me');
      if (!mounted) return;
      await doLogout(context);
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpdAppBar(),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Heading('My profile', subtitle: '${_u['reg_id'] ?? ''} · NIC ${_mask('${_u['nic'] ?? ''}')}'),
        const SizedBox(height: 16),
        Panel(
          child: _edit
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  LabeledField(label: 'Full Name', controller: _name, error: _err['full_name']),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        child: LabeledField(
                            label: 'Age', controller: _age, keyboard: TextInputType.number, error: _err['age'])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SelectField(
                          label: 'Gender',
                          value: _gender,
                          options: const ['Male', 'Female', 'Other'],
                          error: _err['gender'],
                          onChanged: (v) => setState(() => _gender = v)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  LabeledField(
                      label: 'Mobile Number',
                      controller: _mobile,
                      keyboard: TextInputType.phone,
                      error: _err['mobile']),
                  if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
                  const SizedBox(height: 16),
                  PrimaryButton('Save changes', onPressed: _save, loading: _saving),
                  const SizedBox(height: 10),
                  SecondaryButton('Cancel', onPressed: () {
                    setState(() {
                      _edit = false;
                      _err = {};
                      _error = null;
                    });
                    _fill();
                  }),
                ])
              : Column(children: [
                  KeyValueRow('Full name', '${_u['full_name']}', boxed: true),
                  KeyValueRow('Age', '${_u['age']}', boxed: true),
                  KeyValueRow('Gender', '${_u['gender']}', boxed: true),
                  KeyValueRow('Mobile', '${_u['mobile']}', boxed: true),
                  const SizedBox(height: 4),
                  SecondaryButton('Edit profile', onPressed: () => setState(() => _edit = true)),
                ]),
        ),
        const SizedBox(height: 16),
        SecondaryButton('Change password', onPressed: _changePassword),
        const SizedBox(height: 10),
        SecondaryButton('Log out', onPressed: () => doLogout(context)),
        const SizedBox(height: 10),
        SecondaryButton('Delete account', color: C.red, onPressed: _delete),
      ]),
    );
  }

  String _mask(String nic) =>
      nic.length <= 4 ? nic : '${'\u2022' * (nic.length - 4)}${nic.substring(nic.length - 4)}';
}
