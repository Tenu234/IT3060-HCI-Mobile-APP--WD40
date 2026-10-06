import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'booking_wizard_screen.dart';

class OpdSearchScreen extends StatefulWidget {
  final UserModel user;
  const OpdSearchScreen({super.key, required this.user});

  @override
  State<OpdSearchScreen> createState() => _OpdSearchScreenState();
}

class _OpdSearchScreenState extends State<OpdSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _hospitals = [
    {
      'hospital': 'City General Hospital',
      'opds': ['Cardiology OPD', 'Orthopedics OPD', 'Pediatrics OPD'],
    },
    {
      'hospital': 'National Hospital',
      'opds': ['Neurology OPD', 'Dermatology OPD', 'ENT OPD'],
    },
    {
      'hospital': 'Colombo South Hospital',
      'opds': ['General OPD', 'Surgery OPD', 'Ophthalmology OPD'],
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _hospitals;
    return _hospitals.where((h) {
      final hospitalMatch = h['hospital'].toLowerCase().contains(_query);
      final opdMatch = (h['opds'] as List).any(
        (o) => o.toLowerCase().contains(_query),
      );
      return hospitalMatch || opdMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search OPD / Hospital'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search hospital or OPD...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final h = _filtered[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ExpansionTile(
                    leading: const Icon(Icons.local_hospital_outlined, color: Colors.teal),
                    title: Text(h['hospital'],
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    children: (h['opds'] as List<String>).map((opd) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                        leading: const Icon(Icons.medical_services_outlined, size: 20),
                        title: Text(opd),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => BookingWizardScreen(
                              user: widget.user,
                              hospitalName: h['hospital'],
                              opdName: opd,
                            ),
                          ));
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
