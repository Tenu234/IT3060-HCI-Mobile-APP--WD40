import 'package:flutter/material.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

class DailyRegisterScreen extends StatefulWidget {
  const DailyRegisterScreen({super.key});

  @override
  State<DailyRegisterScreen> createState() => _DailyRegisterScreenState();
}

class _DailyRegisterScreenState extends State<DailyRegisterScreen> {
  final StaffApiService _apiService = StaffApiService();
  List<WalkInBooking> _bookings = [];
  List<WalkInBooking> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  final List<String> _doctors = [
    'Dr. Perera',
    'Dr. Silva',
    'Dr. Fernando',
    'Dr. Jayasinghe',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final bookings = await _apiService.getAllBookings();
    setState(() {
      _bookings = bookings;
      _filtered = bookings;
      _isLoading = false;
    });
  }

  void _search(String query) {
    setState(() {
      _filtered = _bookings
          .where((b) =>
              b.patientName.toLowerCase().contains(query.toLowerCase()) ||
              b.doctorName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _deleteBooking(WalkInBooking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Cancel booking for ${booking.patientName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Yes', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && booking.id != null) {
      final success = await _apiService.deleteBooking(booking.id!);
      if (success) {
        _loadBookings();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Booking cancelled'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _updateDoctor(WalkInBooking booking) async {
    String selected = booking.doctorName;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reassign Doctor'),
        content: DropdownButtonFormField<String>(
          value: selected,
          items: _doctors
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (v) => selected = v!,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (booking.id != null) {
                await _apiService
                    .updateBooking(booking.id!, {'doctorName': selected});
                _loadBookings();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'in_consultation':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'absent':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Daily Patient Register',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBookings)
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search by patient or doctor name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No bookings found'))
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final b = _filtered[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _statusColor(b.status),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(b.patientName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(b.doctorName),
                                    Text(b.roomNumber),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _statusColor(b.status)
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        b.status.replaceAll('_', ' ').toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: _statusColor(b.status),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'reassign') _updateDoctor(b);
                                    if (v == 'cancel') _deleteBooking(b);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                        value: 'reassign',
                                        child: Row(children: [
                                          Icon(Icons.swap_horiz),
                                          SizedBox(width: 8),
                                          Text('Reassign Doctor')
                                        ])),
                                    const PopupMenuItem(
                                        value: 'cancel',
                                        child: Row(children: [
                                          Icon(Icons.cancel,
                                              color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Cancel Booking',
                                              style: TextStyle(
                                                  color: Colors.red))
                                        ])),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
