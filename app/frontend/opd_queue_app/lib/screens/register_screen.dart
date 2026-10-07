import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

const _teal = Color(0xFF1A5C6B);
const _bg = Color(0xFFF0F4F5);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 0; // 0=Your details, 1=Verify mobile, 2=Patient ID

  // Step 0 fields
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _abhaController = TextEditingController();
  String? _gender;
  String? _district;
  bool _consent = false;

  // Step 1 fields
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  final List<String> _districts = [
    'Colombo', 'Gampaha', 'Kalutara', 'Kandy',
    'Matale', 'Nuwara Eliya', 'Galle', 'Matara', 'Hambantota',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    _pinController.dispose();
    _abhaController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty ||
          _mobileController.text.trim().isEmpty ||
          _gender == null ||
          !_consent) {
        setState(() => _error = 'Please fill all required fields and confirm consent.');
        return;
      }
      setState(() { _step = 1; _error = null; });
    } else if (_step == 1) {
      // Verify OTP — in real app call backend
      setState(() { _step = 2; _error = null; });
    } else {
      // Registration complete
      setState(() => _isLoading = true);
      try {
        await AuthService.registerUser(
          name: _nameController.text.trim(),
          email: '${_mobileController.text.trim()}@opd.local',
          password: 'temp1234',
          phone: _mobileController.text.trim(),
          nic: _abhaController.text.trim(),
          role: 'patient',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please log in.')),
          );
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } catch (e) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepIndicator(current: _step),
                  const SizedBox(height: 24),
                  if (_step == 0) _buildStep0(),
                  if (_step == 1) _buildStep1(),
                  if (_step == 2) _buildStep2(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(_error!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _PrimaryButton(
                    label: _step < 2 ? 'Continue' : 'Register',
                    isLoading: _isLoading,
                    onPressed: _continue,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFDDE2E6)),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already registered? ',
                          style: TextStyle(
                              color: Color(0xFF6B7280), fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Log in',
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

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Register as a patient',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 6),
        const Text(
            'One-time registration for OPD at District General Hospital.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 24),

        _label('Full name'),
        const SizedBox(height: 8),
        _inputField(
            controller: _nameController,
            hint: 'As on Aadhaar or any govt. ID'),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Date of birth'),
                  const SizedBox(height: 8),
                  _dobField(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Gender'),
                  const SizedBox(height: 8),
                  _genderSelector(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _label('Mobile number'),
        const SizedBox(height: 8),
        _PhoneField(controller: _mobileController),
        const SizedBox(height: 6),
        const Text("We'll send an OTP to verify it.",
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('District'),
                  const SizedBox(height: 8),
                  _districtDropdown(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('PIN code'),
                  const SizedBox(height: 8),
                  _inputField(
                      controller: _pinController,
                      hint: '110001',
                      keyboardType: TextInputType.number),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label('ABHA number'),
            const Text('Optional',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
        const SizedBox(height: 8),
        _inputField(
            controller: _abhaController,
            hint: '14-digit health ID'),
        const SizedBox(height: 6),
        const Text('Links your records across government hospitals.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 16),

        // Consent
        GestureDetector(
          onTap: () => setState(() => _consent = !_consent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _consent,
                  onChanged: (v) =>
                      setState(() => _consent = v ?? false),
                  activeColor: _teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'I confirm these details are correct and consent to the hospital storing my health records for treatment.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verify mobile number',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 6),
        Text('Enter the OTP sent to +94 ${_mobileController.text}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 24),
        _label('Enter OTP'),
        const SizedBox(height: 8),
        _inputField(
            controller: _otpController,
            hint: '6-digit OTP',
            keyboardType: TextInputType.number),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {},
          child: const Text('Resend OTP',
              style: TextStyle(
                  color: _teal,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Patient ID',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 6),
        const Text(
            'Registration complete. Your Patient ID has been generated.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE2E6)),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: _teal, size: 48),
              const SizedBox(height: 12),
              const Text('OPD-2026-XXXXX',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 6),
              const Text('Save this ID to log in next time',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF1A1A2E)));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB0B8BF)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _dobField() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(1990),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          _dobController.text =
              '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
          setState(() {});
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE2E6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _dobController.text.isEmpty
                    ? 'dd/mm/yyyy'
                    : _dobController.text,
                style: TextStyle(
                    color: _dobController.text.isEmpty
                        ? const Color(0xFFB0B8BF)
                        : const Color(0xFF1A1A2E),
                    fontSize: 14),
              ),
            ),
            const Icon(Icons.calendar_month_outlined,
                color: Color(0xFF6B7280), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _genderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE2E6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['Female', 'Male', 'Other'].map((g) {
          final selected = _gender == g;
          return GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: Text(g,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selected
                        ? _teal
                        : const Color(0xFF6B7280))),
          );
        }).toList(),
      ),
    );
  }

  Widget _districtDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE2E6)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _district,
          isExpanded: true,
          hint: const Text('Select',
              style: TextStyle(color: Color(0xFFB0B8BF))),
          items: _districts
              .map((d) =>
                  DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (v) => setState(() => _district = v),
        ),
      ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  static const steps = ['Your details', 'Verify mobile', 'Patient ID'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i <= current;
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                margin: EdgeInsets.only(right: i < steps.length - 1 ? 8 : 0),
                decoration: BoxDecoration(
                  color: active ? _teal : const Color(0xFFDDE2E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              Text(steps[i],
                  style: TextStyle(
                      fontSize: 11,
                      color: active ? _teal : const Color(0xFF9CA3AF))),
            ],
          ),
        );
      }),
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
              border:
                  Border(right: BorderSide(color: Color(0xFFDDE2E6))),
            ),
            child: const Text('+94',
                style: TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '77 123 4567',
                hintStyle:
                    TextStyle(color: Color(0xFFB0B8BF)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
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
