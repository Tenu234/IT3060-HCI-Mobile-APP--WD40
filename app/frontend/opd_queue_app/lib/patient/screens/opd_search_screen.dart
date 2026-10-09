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
      {'name': 'General Medicine OPD', 'info': 'General Medicine OPD operates Monday to Saturday.'},
      {'name': 'Cardiology OPD',       'info': 'Cardiology OPD operates Monday, Wednesday, Friday.'},
      {'name': 'Neurology OPD',        'info': 'Neurology OPD operates Tuesday and Thursday.'},
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
      final hospitalMatch = h.toLowerCase().contains(_query);
      final opdMatch = _hospitals[h]!
          .any((o) => o['name']!.toLowerCase().contains(_query));
      return hospitalMatch || opdMatch;
    }).toList();
  }

  List<Map<String, String>> get _opdsForHospital {
    if (_selectedHospital == null) return [];
    return _hospitals[_selectedHospital] ?? [];
  }

  String? get _selectedOpdInfo {
    if (_selectedOpd == null) return null;
    return _opdsForHospital
        .firstWhere((o) => o['name'] == _selectedOpd,
            orElse: () => {})['info'];
  }

  bool get _canContinue =>
      _selectedHospital != null && _selectedOpd != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Go to dashboard if pushed from login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => PatientDashboard(user: widget.user)),
            );
          },
        ),
        title: const Text('Book Appointment',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: 'Step 1 of 3: ',
                    style: TextStyle(
                        color: Color(0xFF00897B),
                        fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: 'Select OPD',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Hospital or OPD...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _query = v.toLowerCase();
                        _selectedHospital = null;
                        _selectedOpd = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Select Hospital
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87),
                      children: [
                        TextSpan(text: 'Select Hospital '),
                        TextSpan(
                            text: '*',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedHospital,
                    hint: const Text('Select a hospital'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87),
                      children: [
                        TextSpan(text: 'Select OPD / Clinic '),
                        TextSpan(
                            text: '*',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedOpd,
                    hint: const Text('Select OPD'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _selectedOpd != null
                              ? const Color(0xFF00897B)
                              : Colors.grey.shade400,
                          width: _selectedOpd != null ? 1.5 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _selectedOpd != null
                              ? const Color(0xFF00897B)
                              : Colors.grey.shade400,
                          width: _selectedOpd != null ? 1.5 : 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
                  if (_selectedOpdInfo != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF00897B), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedOpdInfo!,
                              style: const TextStyle(
                                  color: Color(0xFF00695C),
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Continue button
          Padding(
            padding: const EdgeInsets.all(16),
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
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue to Date & Slot',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
