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
    with TickerProviderStateMixin {
  final StaffApiService _api = StaffApiService();
  List<WalkInBooking> _queue = [];
  bool _isLoading = true;
  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  final _statuses = [
    'entered_opd', 'waiting_room', 'in_consultation',
    'completed', 'absent', 'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _api.getAllBookings();
    setState(() { _queue = all; _isLoading = false; });
  }

  List<WalkInBooking> get _waiting => _queue
      .where((b) => b.status == 'entered_opd' || b.status == 'waiting_room')
      .toList();

  List<WalkInBooking> get _inRoom => _queue
      .where((b) => b.status == 'in_consultation')
      .toList();

  List<WalkInBooking> get _done => _queue
      .where((b) => b.status == 'completed' || b.status == 'absent' || b.status == 'cancelled')
      .toList();

  WalkInBooking? get _nowServing => _inRoom.isNotEmpty
      ? _inRoom.first
      : (_waiting.isNotEmpty ? _waiting.first : null);

  WalkInBooking? get _nextUp => _waiting.length > 1
      ? _waiting[1]
      : (_waiting.isNotEmpty && _inRoom.isNotEmpty ? _waiting.first : null);

  String _tokenFor(WalkInBooking b) {
    final raw = b.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    return 'Q-${raw.substring(raw.length > 4 ? raw.length - 4 : 0).toUpperCase()}';
  }

  Future<void> _editStatus(WalkInBooking b) async {
    String sel = b.status;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_tokenFor(b),
                      style: const TextStyle(
                          color: kPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(b.patientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16, color: kText)),
                ),
              ]),
              const SizedBox(height: 6),
              Text('${b.doctorName}  ·  ${b.roomNumber}',
                  style: const TextStyle(fontSize: 12, color: kTextMuted)),
              const SizedBox(height: 20),
              const Text('MOVE TO',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: kTextMuted, letterSpacing: 1)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _statuses.map((s) {
                  final active = sel == s;
                  final c = statusColor(s);
                  return GestureDetector(
                    onTap: () => setS(() => sel = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? c : c.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: active ? c : c.withOpacity(0.25)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(statusIcon(s), size: 14,
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
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (b.id != null) {
                      await _api.updateBooking(b.id!, {'status': sel});
                      _load();
                    }
                  },
                  child: const Text('Save Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
      backgroundColor: const Color(0xFF0A1628),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(child: _buildTopBoard()),
              ],
              body: Column(children: [
                // ── Tab bar ──────────────────────────────────────────────
                Container(
                  color: const Color(0xFF0D1F38),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicatorColor: kAccent,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                    unselectedLabelStyle:
                        const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                    tabs: [
                      Tab(text: 'WAITING  ${_waiting.length}'),
                      Tab(text: 'IN ROOM  ${_inRoom.length}'),
                      Tab(text: 'DONE  ${_done.length}'),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: kSurface,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _QueueList(
                          queue: _waiting, tokenFor: _tokenFor,
                          onEdit: _editStatus, onRefresh: _load,
                          emptyMsg: 'No patients waiting',
                          emptyIcon: Icons.hourglass_empty_rounded,
                        ),
                        _QueueList(
                          queue: _inRoom, tokenFor: _tokenFor,
                          onEdit: _editStatus, onRefresh: _load,
                          emptyMsg: 'No active consultations',
                          emptyIcon: Icons.medical_services_rounded,
                        ),
                        _DoneList(queue: _done, tokenFor: _tokenFor),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        onPressed: _load,
        child: const Icon(Icons.refresh_rounded, color: Colors.white),
      ),
    );
  }

  // ── Dark top scoreboard ───────────────────────────────────────────────────
  Widget _buildTopBoard() {
    final now = _nowServing;
    final next = _nextUp;

    return Container(
      color: const Color(0xFF0A1628),
      child: Column(children: [
        // AppBar row
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text('Live Queue Board',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kDone.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kDone.withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Transform.scale(
                      scale: _pulse.value,
                      child: Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: kDone,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text('LIVE',
                      style: TextStyle(
                          color: kDone,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ]),
              ),
              const SizedBox(width: 8),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // ── Now Serving + Next Up side by side ─────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // NOW SERVING — big card
            Expanded(
              flex: 3,
              child: now == null
                  ? _EmptyBoardCard(label: 'NOW SERVING', sub: 'Queue is empty')
                  : _NowServingCard(booking: now, token: _tokenFor(now), pulse: _pulse),
            ),
            const SizedBox(width: 12),
            // NEXT UP + stats stacked
            Expanded(
              flex: 2,
              child: Column(children: [
                next == null
                    ? _EmptyBoardCard(label: 'NEXT UP', sub: '—')
                    : _NextUpCard(booking: next, token: _tokenFor(next)),
                const SizedBox(height: 10),
                // Stats row
                Row(children: [
                  _MiniStat(value: '${_waiting.length}', label: 'Waiting',
                      color: kWaiting),
                  const SizedBox(width: 8),
                  _MiniStat(value: '${_done.length}', label: 'Done',
                      color: kDone),
                ]),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Now serving card (big, animated) ─────────────────────────────────────────
class _NowServingCard extends StatelessWidget {
  final WalkInBooking booking;
  final String token;
  final Animation<double> pulse;
  const _NowServingCard(
      {required this.booking, required this.token, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006D77), Color(0xFF004D56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: kPrimary.withOpacity(0.4),
              blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('NOW SERVING',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.5 + pulse.value * 0.5),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        // Big token
        Text(token,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(booking.patientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(booking.roomNumber,
            style: TextStyle(
                color: Colors.white.withOpacity(0.65), fontSize: 12)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.campaign_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(booking.doctorName,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

// ── Next up card ──────────────────────────────────────────────────────────────
class _NextUpCard extends StatelessWidget {
  final WalkInBooking booking;
  final String token;
  const _NextUpCard({required this.booking, required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('NEXT UP',
            style: TextStyle(
                color: Colors.white54, fontSize: 9,
                fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(token,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(booking.patientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}

// ── Mini stat box ─────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MiniStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ]),
      ),
    );
  }
}

// ── Empty board card ──────────────────────────────────────────────────────────
class _EmptyBoardCard extends StatelessWidget {
  final String label, sub;
  const _EmptyBoardCard({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 9,
                fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 10),
        Text(sub,
            style: const TextStyle(color: Colors.white24, fontSize: 13)),
      ]),
    );
  }
}

// ── Reusable queue list ───────────────────────────────────────────────────────
class _QueueList extends StatelessWidget {
  final List<WalkInBooking> queue;
  final String Function(WalkInBooking) tokenFor;
  final void Function(WalkInBooking) onEdit;
  final Future<void> Function() onRefresh;
  final String emptyMsg;
  final IconData emptyIcon;

  const _QueueList({
    required this.queue,
    required this.tokenFor,
    required this.onEdit,
    required this.onRefresh,
    required this.emptyMsg,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(emptyIcon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(emptyMsg,
              style: const TextStyle(color: kTextMuted, fontSize: 15)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: queue.length,
        itemBuilder: (_, i) {
          final b = queue[i];
          final c = statusColor(b.status);
          return GestureDetector(
            onTap: () => onEdit(b),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: kCardDecoration(),
              child: Row(children: [
                // Colored left bar
                Container(
                  width: 5,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                // Position number
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade300)),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(b.patientName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: kText)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(tokenFor(b),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: kPrimary,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                        ]),
                        const SizedBox(height: 4),
                        Text('${b.doctorName}  ·  ${b.roomNumber}',
                            style: const TextStyle(
                                fontSize: 12, color: kTextMuted)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(statusIcon(b.status), color: c, size: 11),
                            const SizedBox(width: 4),
                            Text(statusLabel(b.status),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: c,
                                    fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
                // Edit arrow
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade400),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ── Done list ─────────────────────────────────────────────────────────────────
class _DoneList extends StatelessWidget {
  final List<WalkInBooking> queue;
  final String Function(WalkInBooking) tokenFor;
  const _DoneList({required this.queue, required this.tokenFor});

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 56, color: Color(0xFFDDE2E6)),
          SizedBox(height: 12),
          Text('No completed patients yet',
              style: TextStyle(color: kTextMuted, fontSize: 15)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: queue.length,
      itemBuilder: (_, i) {
        final b = queue[i];
        final c = statusColor(b.status);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: kCardDecoration(),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon(b.status), color: c, size: 20),
            ),
            title: Row(children: [
              Expanded(
                child: Text(b.patientName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: kText)),
              ),
              Text(tokenFor(b),
                  style: const TextStyle(
                      fontSize: 11, color: kPrimary,
                      fontWeight: FontWeight.bold)),
            ]),
            subtitle: Text('${b.doctorName}  ·  ${b.roomNumber}',
                style: const TextStyle(fontSize: 12, color: kTextMuted)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(statusLabel(b.status),
                  style: TextStyle(
                      fontSize: 11, color: c, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }
}
