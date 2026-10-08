import 'package:flutter/material.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

const _primary = Color(0xFF006D77);

class DailyRegisterScreen extends StatefulWidget {
  const DailyRegisterScreen({super.key});
  @override
  State<DailyRegisterScreen> createState() => _DailyRegisterScreenState();
}

class _DailyRegisterScreenState extends State<DailyRegisterScreen> {
  final StaffApiService _api = StaffApiService();
  List<WalkInBooking> _all = [];
  List<WalkInBooking> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  final _doctors = ['Dr. Perera', 'Dr. Silva', 'Dr. Fernando', 'Dr. Jayasinghe'];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _all = await _api.getAllBookings();
    _applySearch(_searchCtrl.text);
    setState(() => _isLoading = false);
  }

  void _applySearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_all)
          : _all.where((b) =>
              b.patientName.toLowerCase().contains(q.toLowerCase()) ||
              b.doctorName.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  Color _color(String s) {
    switch (s) {
      case 'waiting':
      case 'waiting_room':    return const Color(0xFFE9943A);
      case 'in_consultation': return const Color(0xFF3A7BD5);
      case 'completed':       return const Color(0xFF2ECC71);
      case 'cancelled':       return Colors.red;
      default:                return Colors.grey;
    }
  }

  Future<void> _reassign(WalkInBooking b) async {
    String sel = b.doctorName;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reassign Doctor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ..._doctors.map((d) => RadioListTile<String>(
                    title: Text(d),
                    value: d,
                    groupValue: sel,
                    activeColor: _primary,
                    onChanged: (v) => setS(() => sel = v!),
                  )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (b.id != null) {
                      await _api.updateBooking(b.id!, {'doctorName': sel});
                      _load();
                    }
                  },
                  child: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancel(WalkInBooking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking'),
        content: Text('Cancel booking for ${b.patientName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    if (ok == true && b.id != null) {
      await _api.deleteBooking(b.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Daily Register', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: _primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _applySearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search patient or doctor...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Text('${_filtered.length} patients',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No patients found', style: TextStyle(color: Colors.grey)),
                        ]),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final b = _filtered[i];
                            final c = _color(b.status);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: c.withOpacity(0.12),
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(color: c, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(b.patientName,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                          borderRadius: BorderRadius.circular(20)),
                                      child: Text(b.status.replaceAll('_', ' ').toUpperCase(),
                                          style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (v) {
                                    if (v == 'reassign') _reassign(b);
                                    if (v == 'cancel') _cancel(b);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'reassign',
                                        child: Row(children: [
                                          Icon(Icons.swap_horiz_rounded, size: 18),
                                          SizedBox(width: 10), Text('Reassign Doctor')
                                        ])),
                                    const PopupMenuItem(value: 'cancel',
                                        child: Row(children: [
                                          Icon(Icons.cancel_rounded, color: Colors.red, size: 18),
                                          SizedBox(width: 10),
                                          Text('Cancel', style: TextStyle(color: Colors.red))
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
