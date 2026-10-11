import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'booking_wizard_screen.dart';
import 'patient_dashboard.dart';

class OpdSearchScreen extends StatefulWidget {
  final UserModel user;
  const OpdSearchScreen({super.key, required this.user});

  @override
  State<OpdSearchScreen> createState() => _OpdSearchScreenState();
}

class _OpdSearchScreenState extends State<OpdSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedHospital;
  String? _selectedOpd;

  final Map<String, List<Map<String, String>>> _hospitals = {
    'National Hospital of Sri Lanka': [
      {'name': 'General Medicine OPD',  'info': 'General Medicine OPD operates Monday to Saturday.'},
      {'name': 'Cardiology OPD',        'info': 'Cardiology OPD operates Monday, Wednesday, Friday.'},
      {'name': 'Neurology OPD',         'info': 'Neurology OPD operates Tuesday and Thursday.'},
    ],
    'City General Hospital': [
      {'name': 'Orthopedics OPD',  'info': 'Orthopedics OPD operates Monday to Friday.'},
      {'name': 'Pediatrics OPD',   'info': 'Pediatrics OPD operates daily except Sunday.'},
      {'name': 'ENT OPD',          'info': 'ENT OPD operates Monday, Wednesday, Friday.'},
    ],
    'Colombo South Hospital': [
      {'name': 'Surgery OPD',       'info': 'Surgery OPD operates Monday to Saturday.'},
      {'name': 'Ophthalmology OPD', 'info': 'Ophthalmology OPD operates Tuesday and Thursday.'},
      {'name': 'Dermatology OPD',   'info': 'Dermatology OPD operates Monday to Friday.'},
    ],
  };

  List<String> get _filteredHospitals {
    if (_query.isEmpty) return _hospitals.keys.toList();
    return _hospitals.keys.where((h) {
      final hMatch = h.toLowerCase().contains(_query);
      final oMatch = _hospitals[h]!.any((o) => o['name']!.toLowerCase().contains(_query));
      return hMatch || oMatch;
    }).toList();
  }

  List<Map<String, String>> get _opdsForHospital =>
      _selectedHospital == null ? [] : (_hospitals[_selectedHospital] ?? []);

  String? get _opdInfo => _selectedOpd == null
      ? null
      : _opdsForHospital.firstWhere(
          (o) => o['name'] == _selectedOpd, orElse: () => {})['info'];

  bool get _canContinue => _selectedHospital != null && _selectedOpd != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Soothing medical background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5C6B), // Rich medical teal
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'My Appointments',
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => PatientDashboard(user: widget.user)),
          ),
        ),
        title: const Text(
          'Book OPD Appointment',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month_rounded, size: 16),
              label: const Text(
                'My Appointments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFF80CBC4), width: 1),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientDashboard(user: widget.user),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick navigation banner to My Appointments
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE0F2FE), Color(0xFFE0F7FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB2EBF2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF006D77).withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006D77).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: Color(0xFF006D77),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Already Have an Appointment?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Track live token numbers & wait times',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDashboard(user: widget.user),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5C6B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text(
                    'My Appointments',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Step banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Step 1 of 3',
                    style: TextStyle(
                      color: Color(0xFF00796B),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Select Hospital & OPD Clinic',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Hospital or OPD Clinic...',
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Color(0xFF0D9488)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (v) {
                        setState(() {
                          _query = v.toLowerCase();
                          _selectedHospital = null;
                          _selectedOpd = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selection Card Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Select Hospital
                        _fieldLabel('Select Hospital'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedHospital,
                          hint: const Text('Choose a government hospital'),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.local_hospital_rounded,
                                color: Color(0xFF1A5C6B), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1A5C6B), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                          ),
                          items: _filteredHospitals
                              .map((h) => DropdownMenuItem(
                                    value: h,
                                    child: Text(h,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedHospital = v;
                            _selectedOpd = null;
                          }),
                        ),
                        const SizedBox(height: 20),

                        // Select OPD
                        _fieldLabel('Select OPD Clinic'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedOpd,
                          hint: Text(_selectedHospital == null
                              ? 'Select a hospital first'
                              : 'Choose OPD specialty'),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                                Icons.medical_services_rounded,
                                color: Color(0xFF1A5C6B),
                                size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _selectedOpd != null
                                    ? const Color(0xFF0D9488)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1A5C6B), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                          ),
                          items: _opdsForHospital
                              .map((o) => DropdownMenuItem(
                                    value: o['name'],
                                    child: Text(o['name']!),
                                  ))
                              .toList(),
                          onChanged: _selectedHospital == null
                              ? null
                              : (v) => setState(() => _selectedOpd = v),
                        ),

                        // Info banner
                        if (_opdInfo != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA), // Soft mint
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF99F6E4)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_rounded,
                                    color: Color(0xFF0D9488), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _opdInfo!,
                                    style: const TextStyle(
                                      color: Color(0xFF0F766E),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Continue button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canContinue
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingWizardScreen(
                              user: widget.user,
                              hospitalName: _selectedHospital!,
                              opdName: _selectedOpd!,
                            ),
                          ),
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5C6B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue to Date & Slot',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => RichText(
        text: TextSpan(
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(text: '$text '),
            const TextSpan(
                text: '*', style: TextStyle(color: Colors.red)),
          ],
        ),
      );
}
