import 'package:flutter/material.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

class PatientStatusUpdateScreen extends StatefulWidget {
  const PatientStatusUpdateScreen({super.key});

  @override
  State<PatientStatusUpdateScreen> createState() =>
      _PatientStatusUpdateScreenState();
}

class _PatientStatusUpdateScreenState
    extends State<PatientStatusUpdateScreen> {
  final StaffApiService _apiService = StaffApiService();
  List<WalkInBooking> _bookings = [];
  bool _isLoading = true;

  // Status flow order
  final List<Map<String, dynamic>> _statusFlow = [
    {
      'value': 'entered_opd',
      'label': 'Entered OPD',
      'icon': Icons.login,
      'color': Colors.teal,
    },
    {
      'value': 'waiting_room',
      'label': 'Waiting Room',
      'icon': Icons.hourglass_empty,
      'color': Colors.orange,
    },
    {
      'value': 'in_consultation',
      'label': 'In Consultation',
      'icon': Icons.medical_services,
      'color': Colors.blue,
    },
    {
      'value': 'completed',
      'label': 'Completed',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final bookings = await _apiService.getAllBookings();
    setState(() {
      _bookings = bookings
          .where((b) => b.status != 'cancelled' && b.status != 'absent')
          .toList();
      _isLoading = false;
    });
  }

  int _statusIndex(String status) {
    return _statusFlow.indexWhere((s) => s['value'] == status);
  }

  Future<void> _progressStatus(WalkInBooking booking) async {
    final currentIndex = _statusIndex(booking.status);
    if (currentIndex < _statusFlow.length - 1) {
      final nextStatus = _statusFlow[currentIndex + 1]['value'] as String;
      if (booking.id != null) {
        await _apiService.updateBooking(booking.id!, {'status': nextStatus});
        _loadBookings();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${booking.patientName} moved to ${nextStatus.replaceAll('_', ' ')}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _markAbsent(WalkInBooking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Absent'),
        content: Text('Mark ${booking.patientName} as absent?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && booking.id != null) {
      await _apiService.updateBooking(booking.id!, {'status': 'absent'});
      _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Patient marked as absent'),
            backgroundColor: Colors.orange),
      );
    }
  }

  Color _getStatusColor(String status) {
    final s = _statusFlow.firstWhere(
      (e) => e['value'] == status,
      orElse: () => {'color': Colors.grey},
    );
    return s['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Patient Turn Status',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadBookings),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status flow indicator
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 8),
                  child: Row(
                    children: _statusFlow.map((s) {
                      final index = _statusFlow.indexOf(s);
                      final isLast = index == _statusFlow.length - 1;
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        s['color'] as Color,
                                    child: Icon(
                                        s['icon'] as IconData,
                                        color: Colors.white,
                                        size: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s['label'] as String,
                                    style: const TextStyle(
                                        fontSize: 9),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              const Icon(Icons.arrow_forward,
                                  size: 14, color: Colors.grey),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Patient list
                Expanded(
                  child: _bookings.isEmpty
                      ? const Center(
                          child: Text('No active patients',
                              style: TextStyle(color: Colors.grey)))
                      : RefreshIndicator(
                          onRefresh: _loadBookings,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _bookings.length,
                            itemBuilder: (context, index) {
                              final b = _bookings[index];
                              final currentIndex =
                                  _statusIndex(b.status);
                              final canProgress =
                                  currentIndex <
                                      _statusFlow.length - 1;

                              return Card(
                                margin:
                                    const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Text(b.patientName,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 16)),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8,
                                                vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                      b.status)
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8),
                                            ),
                                            child: Text(
                                              b.status
                                                  .replaceAll('_', ' ')
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      _getStatusColor(
                                                          b.status),
                                                  fontWeight:
                                                      FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                          '${b.doctorName} — ${b.roomNumber}',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                      const SizedBox(height: 12),

                                      // Progress stepper
                                      Row(
                                        children: List.generate(
                                          _statusFlow.length,
                                          (i) => Expanded(
                                            child: Container(
                                              height: 6,
                                              margin: EdgeInsets.only(
                                                  right: i <
                                                          _statusFlow
                                                                  .length -
                                                              1
                                                      ? 4
                                                      : 0),
                                              decoration: BoxDecoration(
                                                color: i <=
                                                        currentIndex
                                                    ? (_statusFlow[i][
                                                            'color']
                                                        as Color)
                                                    : Colors.grey
                                                        .shade200,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(3),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      Row(
                                        children: [
                                          if (canProgress)
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () =>
                                                    _progressStatus(b),
                                                icon: const Icon(
                                                    Icons.arrow_forward,
                                                    size: 16),
                                                label: Text(
                                                  'Move to ${(_statusFlow[currentIndex + 1]['label'] as String)}',
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                      const Color(
                                                          0xFF1565C0),
                                                  foregroundColor:
                                                      Colors.white,
                                                ),
                                              ),
                                            ),
                                          if (canProgress)
                                            const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _markAbsent(b),
                                            icon: const Icon(
                                                Icons.person_off,
                                                size: 16,
                                                color: Colors.red),
                                            label: const Text('Absent',
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 12)),
                                          ),
                                        ],
                                      ),
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
