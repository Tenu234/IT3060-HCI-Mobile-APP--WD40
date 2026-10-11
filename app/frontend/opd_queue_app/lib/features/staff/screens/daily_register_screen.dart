import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';
import 'patient_history_screen.dart';
import 'patient_queue_status_screen.dart';

class DailyRegisterScreen extends StatefulWidget {
  const DailyRegisterScreen({super.key});
  @override
  State<DailyRegisterScreen> createState() => _DailyRegisterScreenState();
}

class _DailyRegisterScreenState extends State<DailyRegisterScreen> {
  final StaffApiService _api = StaffApiService();
  List<WalkInBooking> _all      = [];
  List<WalkInBooking> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();
  String _filterStatus = 'all';

  final _doctors = ['Dr. Perera', 'Dr. Silva', 'Dr. Fernando', 'Dr. Jayasinghe'];

  final _filterOptions = [
    {'value': 'all',            'label': 'All'},
    {'value': 'entered_opd',    'label': 'Entered'},
    {'value': 'waiting_room',   'label': 'Waiting'},
    {'value': 'in_consultation','label': 'In Room'},
    {'value': 'completed',      'label': 'Done'},
    {'value': 'cancelled',      'label': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _all = await _api.getAllBookings();
    _applyFilter();
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((b) {
        final matchSearch = q.isEmpty ||
            b.patientName.toLowerCase().contains(q) ||
            b.doctorName.toLowerCase().contains(q);
        final matchStatus = _filterStatus == 'all' || b.status == _filterStatus;
        return matchSearch && matchStatus;
      }).toList();
    });
  }

  String _tokenFor(WalkInBooking b) {
    final raw = b.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    return 'Q-${raw.substring(raw.length > 4 ? raw.length - 4 : 0).toUpperCase()}';
  }

  Future<void> _reassign(WalkInBooking b) async {
    String sel = b.doctorName;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Reassign Doctor',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kText)),
            const SizedBox(height: 16),
            ..._doctors.map((d) => RadioListTile<String>(
                  title: Text(d),
                  value: d,
                  groupValue: sel,
                  activeColor: kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onChanged: (v) => setS(() => sel = v!),
                )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  if (b.id != null) {
                    await _api.updateBooking(b.id!, {'doctorName': sel});
                    _load();
                  }
                },
                child: const Text('Update',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _cancel(WalkInBooking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking'),
        content: Text(
            'Cancel booking for ${b.patientName} (${_tokenFor(b)})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kCancelled,
                foregroundColor: Colors.white),
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
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Appointment Register',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applyFilter(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search patient or doctor...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Colors.white60, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: Column(children: [
        // ── Status filter chips ──────────────────────────────────────────
        Container(
          color: Colors.white,
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _filterOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final opt = _filterOptions[i];
              final active = _filterStatus == opt['value'];
              return GestureDetector(
                onTap: () {
                  setState(() => _filterStatus = opt['value']!);
                  _applyFilter();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? kPrimary : kSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: active ? kPrimary : const Color(0xFFE5E7EB)),
                  ),
                  child: Text(opt['label']!,
                      style: TextStyle(
                          fontSize: 12,
                          color: active ? Colors.white : kTextMuted,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              );
            },
          ),
        ),

        // ── Count bar ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Text('${_filtered.length} patients',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kText,
                    fontSize: 13)),
          ]),
        ),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: kPrimary))
              : _filtered.isEmpty
                  ? _EmptyState(
                      hasSearch: _searchCtrl.text.isNotEmpty ||
                          _filterStatus != 'all')
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: kPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final b = _filtered[i];
                          final c = statusColor(b.status);
                          return GestureDetector(
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => PatientQueueStatusScreen(
                                patientPhone: b.patientPhone,
                                patientName:  b.patientName,
                              ))),
                            child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: kCardDecoration(),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                              leading: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 38, height: 38,
                                    decoration: BoxDecoration(
                                      color: kPrimary.withOpacity(0.08),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text('${i + 1}',
                                          style: const TextStyle(
                                              color: kPrimary,
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                              title: Row(children: [
                                Expanded(
                                  child: Text(b.patientName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: kText)),
                                ),
                                // Token chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.08),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(_tokenFor(b),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: kPrimary,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ]),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 3),
                                  Text(
                                      '${b.doctorName}  ·  ${b.roomNumber}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: kTextMuted)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: c.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                        statusLabel(b.status),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: c,
                                            fontWeight:
                                                FontWeight.bold)),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: kTextMuted),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                                onSelected: (v) {
                                  if (v == 'history')  Navigator.push(context, MaterialPageRoute(builder: (_) => PatientHistoryScreen(booking: b)));
                                  if (v == 'reassign') _reassign(b);
                                  if (v == 'cancel') _cancel(b);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'history',
                                    child: Row(children: [
                                      Icon(Icons.history_rounded,
                                          size: 18, color: kPrimary),
                                      SizedBox(width: 10),
                                      Text('View History'),
                                    ]),
                                  ),
                                  const PopupMenuItem(
                                    value: 'reassign',
                                    child: Row(children: [
                                      Icon(Icons.swap_horiz_rounded,
                                          size: 18, color: kPrimary),
                                      SizedBox(width: 10),
                                      Text('Reassign Doctor'),
                                    ]),
                                  ),
                                  const PopupMenuItem(
                                    value: 'cancel',
                                    child: Row(children: [
                                      Icon(Icons.cancel_rounded,
                                          size: 18, color: kCancelled),
                                      SizedBox(width: 10),
                                      Text('Cancel Booking',
                                          style: TextStyle(
                                              color: kCancelled)),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                          ),  // closes GestureDetector
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off_rounded : Icons.inbox_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              hasSearch ? 'No matching patients' : 'No patients today',
              style: const TextStyle(color: kTextMuted, fontSize: 15),
            ),
          ],
        ),
      );
}
