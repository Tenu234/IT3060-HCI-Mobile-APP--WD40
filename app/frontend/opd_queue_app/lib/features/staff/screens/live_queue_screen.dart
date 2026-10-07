import 'package:flutter/material.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

class LiveQueueScreen extends StatefulWidget {
  const LiveQueueScreen({super.key});

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen> {
  final StaffApiService _apiService = StaffApiService();
  List<WalkInBooking> _queue = [];
  bool _isLoading = true;

  final List<String> _statuses = [
    'entered_opd',
    'waiting_room',
    'in_consultation',
    'completed',
    'absent',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    final bookings = await _apiService.getAllBookings();
    setState(() {
      // show only active patients (not completed/cancelled)
      _queue = bookings
          .where((b) =>
              b.status != 'completed' &&
              b.status != 'cancelled' &&
              b.status != 'absent')
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(WalkInBooking booking) async {
    String selected = booking.status;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Update Status — ${booking.patientName}'),
        content: DropdownButtonFormField<String>(
          value: selected,
          items: _statuses
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.replaceAll('_', ' ').toUpperCase()),
                  ))
              .toList(),
          onChanged: (v) => selected = v!,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              if (booking.id != null) {
                await _apiService
                    .updateBooking(booking.id!, {'status': selected});
                _loadQueue();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Status updated'),
                      backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromQueue(WalkInBooking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove from Queue'),
        content: Text(
            'Remove ${booking.patientName} from the active queue?'),
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
      _loadQueue();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Patient removed from queue'),
            backgroundColor: Colors.orange),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'entered_opd':
        return Colors.teal;
      case 'waiting_room':
        return Colors.orange;
      case 'in_consultation':
        return Colors.blue;
      case 'absent':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'entered_opd':
        return Icons.login;
      case 'waiting_room':
        return Icons.hourglass_empty;
      case 'in_consultation':
        return Icons.medical_services;
      case 'absent':
        return Icons.person_off;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Live Queue Board',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadQueue),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _queue.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.queue, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No active patients in queue',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadQueue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _queue.length,
                    itemBuilder: (context, index) {
                      final b = _queue[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(b.status),
                            child: Icon(_statusIcon(b.status),
                                color: Colors.white, size: 20),
                          ),
                          title: Text(b.patientName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${b.doctorName} — ${b.roomNumber}'),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _statusColor(b.status)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  b.status
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _statusColor(b.status),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Update status
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Color(0xFF6A1B9A)),
                                onPressed: () => _updateStatus(b),
                                tooltip: 'Update Status',
                              ),
                              // Remove from queue
                              IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () => _removeFromQueue(b),
                                tooltip: 'Remove from Queue',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
