import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

class LiveQueueScreen extends StatefulWidget {
  const LiveQueueScreen({super.key});
  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen>
    with SingleTickerProviderStateMixin {
  final StaffApiService _api = StaffApiService();
  List<WalkInBooking> _queue = [];
  bool _isLoading = true;
  late TabController _tabCtrl;

  final _statuses = [
    'entered_opd', 'waiting_room', 'in_consultation',
    'completed', 'absent', 'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _api.getAllBookings();
    setState(() {
      _queue = all;
      _isLoading = false;
    });
  }

  List<WalkInBooking> get _active => _queue
      .where((b) =>
          b.status != 'completed' &&
          b.status != 'cancelled' &&
          b.status != 'absent')
      .toList();

  List<WalkInBooking> get _done => _queue
      .where((b) =>
          b.status == 'completed' ||
          b.status == 'cancelled' ||
          b.status == 'absent')
      .toList();

  // Next token to be called = first in waiting_room or entered_opd
  WalkInBooking? get _next => _active.isNotEmpty
      ? _active.firstWhere(
          (b) => b.status == 'waiting_room' || b.status == 'entered_opd',
          orElse: () => _active.first)
      : null;

  String _tokenFor(WalkInBooking b) {
    final raw = b.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    return 'Q-${raw.substring(raw.length > 4 ? raw.length - 4 : 0).toUpperCase()}';
  }

  Future<void> _editStatus(WalkInBooking b) async {
    String sel = b.status;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              Text('Update  ·  ${b.patientName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kText)),
              Text(_tokenFor(b),
                  style: const TextStyle(
                      fontSize: 13,
                      color: kPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _statuses.map((s) {
                  final active = sel == s;
                  final c = statusColor(s);
                  return GestureDetector(
                    onTap: () => setS(() => sel = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: active ? c : c.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: active ? c : c.withOpacity(0.2)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(statusIcon(s),
                            size: 14,
                            color: active ? Colors.white : c),
                        const SizedBox(width: 6),
                        Text(statusLabel(s),
                            style: TextStyle(
                                fontSize: 12,
                                color: active ? Colors.white : c,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
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
                      await _api.updateBooking(b.id!, {'status': sel});
                      _load();
                    }
                  },
                  child: const Text('Save Status',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Live Queue Board',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Active  (${_active.length})'),
            Tab(text: 'Completed  (${_done.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _ActiveTab(
                  queue: _active,
                  next: _next,
                  tokenFor: _tokenFor,
                  onEdit: _editStatus,
                  onRefresh: _load,
                ),
                _DoneTab(queue: _done, tokenFor: _tokenFor),
              ],
            ),
    );
  }
}

// ── Active tab ────────────────────────────────────────────────────────────────
class _ActiveTab extends StatelessWidget {
  final List<WalkInBooking> queue;
  final WalkInBooking? next;
  final String Function(WalkInBooking) tokenFor;
  final void Function(WalkInBooking) onEdit;
  final Future<void> Function() onRefresh;

  const _ActiveTab({
    required this.queue,
    required this.next,
    required this.tokenFor,
    required this.onEdit,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return const _EmptyState(
          icon: Icons.queue_rounded, message: 'No active patients');
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── NOW SERVING banner ─────────────────────────────────────────
          if (next != null) ...[
            _NowServingBanner(booking: next!, token: tokenFor(next!)),
            const SizedBox(height: 16),
          ],

          // ── Queue list ─────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('QUEUE SEQUENCE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kTextMuted,
                    letterSpacing: 1)),
          ),
          ...queue.asMap().entries.map((e) {
            final i = e.key;
            final b = e.value;
            return _QueueTile(
              booking: b,
              position: i + 1,
              token: tokenFor(b),
              onEdit: () => onEdit(b),
            );
          }),
        ],
      ),
    );
  }
}

// ── Now serving banner ────────────────────────────────────────────────────────
class _NowServingBanner extends StatelessWidget {
  final WalkInBooking booking;
  final String token;
  const _NowServingBanner({required this.booking, required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, Color(0xFF008080)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: kPrimary.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        // Token badge
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('NOW',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              Text(token,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NOW SERVING',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(booking.patientName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('${booking.doctorName}  ·  ${booking.roomNumber}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        // Call icon
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.campaign_rounded,
              color: Colors.white, size: 22),
        ),
      ]),
    );
  }
}

// ── Queue tile ────────────────────────────────────────────────────────────────
class _QueueTile extends StatelessWidget {
  final WalkInBooking booking;
  final int position;
  final String token;
  final VoidCallback onEdit;
  const _QueueTile(
      {required this.booking,
      required this.position,
      required this.token,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(booking.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: kCardDecoration(),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('$position',
                    style: const TextStyle(
                        color: kPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
        title: Row(children: [
          Expanded(
            child: Text(booking.patientName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kText)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(token,
                style: const TextStyle(
                    fontSize: 11,
                    color: kPrimary,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text('${booking.doctorName}  ·  ${booking.roomNumber}',
                style: const TextStyle(fontSize: 12, color: kTextMuted)),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon(booking.status), color: c, size: 11),
                const SizedBox(width: 4),
                Text(statusLabel(booking.status),
                    style: TextStyle(
                        fontSize: 11,
                        color: c,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_rounded, color: kPrimary, size: 20),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

// ── Done/completed tab ────────────────────────────────────────────────────────
class _DoneTab extends StatelessWidget {
  final List<WalkInBooking> queue;
  final String Function(WalkInBooking) tokenFor;
  const _DoneTab({required this.queue, required this.tokenFor});

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return const _EmptyState(
          icon: Icons.check_circle_outline_rounded,
          message: 'No completed patients yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: queue.length,
      itemBuilder: (_, i) {
        final b = queue[i];
        final c = statusColor(b.status);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: kCardDecoration(),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon(b.status), color: c, size: 20),
            ),
            title: Text(b.patientName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kText)),
            subtitle: Text(
                '${tokenFor(b)}  ·  ${b.doctorName}',
                style: const TextStyle(
                    fontSize: 12, color: kTextMuted)),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(statusLabel(b.status),
                  style: TextStyle(
                      fontSize: 11,
                      color: c,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(message,
                style: const TextStyle(color: kTextMuted, fontSize: 15)),
          ],
        ),
      );
}
