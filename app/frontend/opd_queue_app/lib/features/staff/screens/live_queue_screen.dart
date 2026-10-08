import 'package:flutter/material.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

const _primary = Color(0xFF006D77);

class LiveQueueScreen extends StatefulWidget {
  const LiveQueueScreen({super.key});
  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen> {
  final StaffApiService _api = StaffApiService();
  List<WalkInBooking> _queue = [];
  bool _isLoading = true;

  final _statuses = ['entered_opd', 'waiting_room', 'in_consultation', 'completed', 'absent', 'cancelled'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _api.getAllBookings();
    setState(() {
      _queue = all.where((b) => b.status != 'completed' && b.status != 'cancelled' && b.status != 'absent').toList();
      _isLoading = false;
    });
  }

  Color _color(String s) {
    switch (s) {
      case 'entered_opd':     return const Color(0xFF006D77);
      case 'waiting_room':    return const Color(0xFFE9943A);
      case 'in_consultation': return const Color(0xFF3A7BD5);
      default:                return Colors.grey;
    }
  }

  IconData _icon(String s) {
    switch (s) {
      case 'entered_opd':     return Icons.login_rounded;
      case 'waiting_room':    return Icons.hourglass_empty_rounded;
      case 'in_consultation': return Icons.medical_services_rounded;
      default:                return Icons.person_rounded;
    }
  }

  String _label(String s) => s.replaceAll('_', ' ').toUpperCase();

  Future<void> _editStatus(WalkInBooking b) async {
    String sel = b.status;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update — ${b.patientName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _statuses.map((s) {
                  final active = sel == s;
                  return GestureDetector(
                    onTap: () => setS(() => sel = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? _primary : const Color(0xFFF0F4F4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_label(s),
                          style: TextStyle(
                              fontSize: 12,
                              color: active ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (b.id != null) {
                      await _api.updateBooking(b.id!, {'status': sel});
                      _load();
                    }
                  },
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Live Queue', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _queue.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.queue_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('No active patients', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _queue.length,
                    itemBuilder: (_, i) {
                      final b = _queue[i];
                      final c = _color(b.status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_icon(b.status), color: c, size: 22),
                          ),
                          title: Text(b.patientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text('${b.doctorName}  ·  ${b.roomNumber}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(_label(b.status),
                                    style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_rounded, color: _primary),
                            onPressed: () => _editStatus(b),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
