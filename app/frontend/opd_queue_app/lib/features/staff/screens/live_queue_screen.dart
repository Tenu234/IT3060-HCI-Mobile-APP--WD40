import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../models/walk_in_booking.dart';
import '../services/staff_api_service.dart';

// ── Banner slide data ─────────────────────────────────────────────────────────
const _kBanners = [
  {
    'title': 'Hand Hygiene Saves Lives',
    'sub': 'Clean hands protect patients and staff',
    'icon': Icons.clean_hands_rounded,
    'grad': [Color(0xFF00897B), Color(0xFF004D56)],
  },
  {
    'title': 'Wear Your Mask Correctly',
    'sub': 'Cover nose and mouth at all times in OPD',
    'icon': Icons.masks_rounded,
    'grad': [Color(0xFF1565C0), Color(0xFF0D47A1)],
  },
  {
    'title': 'Please Keep Distance',
    'sub': 'Maintain 1 m gap in the waiting area',
    'icon': Icons.social_distance_rounded,
    'grad': [Color(0xFF6A1B9A), Color(0xFF4A148C)],
  },
  {
    'title': 'Follow Queue Token Order',
    'sub': 'Wait for your token to be called',
    'icon': Icons.confirmation_number_rounded,
    'grad': [Color(0xFFE65100), Color(0xFFBF360C)],
  },
];

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

  // Pulse for LIVE dot
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // Banner auto-scroll
  final PageController _bannerCtrl = PageController();
  int _bannerPage = 0;
  Timer? _bannerTimer;

  final _statuses = [
    'entered_opd', 'waiting_room', 'in_consultation',
    'completed', 'absent', 'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _load();

    // Auto-advance banners every 4 s
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerPage + 1) % _kBanners.length;
      _bannerCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
      setState(() => _bannerPage = next);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _bannerCtrl.dispose();
    _bannerTimer?.cancel();
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
  List<WalkInBooking> get _inRoom =>
      _queue.where((b) => b.status == 'in_consultation').toList();
  List<WalkInBooking> get _done => _queue
      .where((b) =>
          b.status == 'completed' ||
          b.status == 'absent' ||
          b.status == 'cancelled')
      .toList();

  WalkInBooking? get _nowServing =>
      _inRoom.isNotEmpty ? _inRoom.first : (_waiting.isNotEmpty ? _waiting.first : null);

  WalkInBooking? get _nextUp {
    if (_inRoom.isNotEmpty && _waiting.isNotEmpty) return _waiting.first;
    if (_waiting.length > 1) return _waiting[1];
    return null;
  }

  String _tokenFor(WalkInBooking b) {
    final raw = b.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    return 'Q-${raw.substring(raw.length > 4 ? raw.length - 4 : 0).toUpperCase()}';
  }

  // ── Status editor bottom sheet ────────────────────────────────────────────
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
              color: Colors.white, borderRadius: BorderRadius.circular(24)),
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
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_tokenFor(b),
                      style: const TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(b.patientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kText)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('${b.doctorName}  ·  ${b.roomNumber}',
                  style: const TextStyle(fontSize: 12, color: kTextMuted)),
              const SizedBox(height: 20),
              const Text('MOVE TO',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kTextMuted,
                      letterSpacing: 1)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? c : c.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: active ? c : c.withOpacity(0.25)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(statusIcon(s),
                            size: 14, color: active ? Colors.white : c),
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
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Column(children: [
              // ── TOP PANEL (lighter teal gradient) ──────────────────────
              _buildTopPanel(),

              // ── TAB BAR ────────────────────────────────────────────────
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: kPrimary,
                  indicatorWeight: 3,
                  labelColor: kPrimary,
                  unselectedLabelColor: kTextMuted,
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

              // ── BANNER CAROUSEL ────────────────────────────────────────
              _buildBannerCarousel(),

              // ── LIST CONTENT ───────────────────────────────────────────
              Expanded(
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
            ]),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: kPrimary,
        onPressed: _load,
        child: const Icon(Icons.refresh_rounded, color: Colors.white),
      ),
    );
  }

  // ── Lighter top panel ─────────────────────────────────────────────────────
  Widget _buildTopPanel() {
    final now = _nowServing;
    final next = _nextUp;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00A896), Color(0xFF006D77)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // AppBar row
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Live Queue Board',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              // LIVE pill
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                            .withOpacity(0.5 + _pulse.value * 0.5),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ]),
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // Now serving + Next up + stats
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // NOW SERVING
              Expanded(
                flex: 3,
                child: now == null
                    ? _LightEmptyCard(label: 'NOW SERVING', sub: 'Queue empty')
                    : _NowServingCard(booking: now, token: _tokenFor(now)),
              ),
              const SizedBox(width: 10),
              // Next + stats
              Expanded(
                flex: 2,
                child: Column(children: [
                  next == null
                      ? _LightEmptyCard(label: 'NEXT UP', sub: '—')
                      : _NextUpCard(booking: next, token: _tokenFor(next)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _MiniStat(value: '${_waiting.length}',
                        label: 'Waiting', color: kWaiting),
                    const SizedBox(width: 8),
                    _MiniStat(value: '${_done.length}',
                        label: 'Done', color: Colors.white),
                  ]),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Banner carousel ───────────────────────────────────────────────────────
  Widget _buildBannerCarousel() {
    return Column(children: [
      SizedBox(
        height: 90,
        child: PageView.builder(
          controller: _bannerCtrl,
          onPageChanged: (i) => setState(() => _bannerPage = i),
          itemCount: _kBanners.length,
          itemBuilder: (_, i) {
            final b = _kBanners[i];
            final grads = b['grad'] as List<Color>;
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: grads,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: grads[0].withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(b['icon'] as IconData,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(b['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      const SizedBox(height: 3),
                      Text(b['sub'] as String,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 11)),
                    ],
                  ),
                ),
              ]),
            );
          },
        ),
      ),
      // Dots indicator
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_kBanners.length, (i) {
          final active = i == _bannerPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? kPrimary : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
      const SizedBox(height: 6),
    ]);
  }
}

// ── Now serving card ──────────────────────────────────────────────────────────
class _NowServingCard extends StatelessWidget {
  final WalkInBooking booking;
  final String token;
  const _NowServingCard({required this.booking, required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('NOW SERVING',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
        const SizedBox(height: 8),
        Text(token,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(booking.patientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('${booking.roomNumber}  ·  ${booking.doctorName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 11)),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('NEXT UP',
            style: TextStyle(
                color: Colors.white60, fontSize: 9,
                fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(token,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(booking.patientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }
}

// ── Mini stat ─────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MiniStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ]),
      ),
    );
  }
}

// ── Light empty card ──────────────────────────────────────────────────────────
class _LightEmptyCard extends StatelessWidget {
  final String label, sub;
  const _LightEmptyCard({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 9,
                fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(sub,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }
}

// ── Queue list ────────────────────────────────────────────────────────────────
class _QueueList extends StatelessWidget {
  final List<WalkInBooking> queue;
  final String Function(WalkInBooking) tokenFor;
  final void Function(WalkInBooking) onEdit;
  final Future<void> Function() onRefresh;
  final String emptyMsg;
  final IconData emptyIcon;

  const _QueueList({
    required this.queue, required this.tokenFor,
    required this.onEdit, required this.onRefresh,
    required this.emptyMsg, required this.emptyIcon,
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
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
                  width: 5, height: 76,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                // Position
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade300)),
                  ),
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
                                    fontSize: 14, color: kText)),
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
                                    fontSize: 11, color: kPrimary,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                        ]),
                        const SizedBox(height: 3),
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
                                    fontSize: 11, color: c,
                                    fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
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
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: c.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(statusIcon(b.status), color: c, size: 20),
            ),
            title: Row(children: [
              Expanded(
                child: Text(b.patientName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, color: kText)),
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
                  borderRadius: BorderRadius.circular(20)),
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
