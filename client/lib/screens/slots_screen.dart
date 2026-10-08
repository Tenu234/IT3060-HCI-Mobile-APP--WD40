import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';

class SlotsScreen extends StatefulWidget {
  final int clinicId;
  final Map<String, dynamic>? bookForPatient;
  const SlotsScreen({super.key, required this.clinicId, this.bookForPatient});
  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  Map<String, dynamic>? _clinic;
  List<Map<String, dynamic>> _slots = [];
  String? _date;
  int? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Api.i.get('/clinics/${widget.clinicId}');
      if (!mounted) return;
      final slots = (r['slots'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _clinic = Map<String, dynamic>.from(r['clinic'] as Map);
        _slots = slots;
        _date = slots.isEmpty ? null : slots.first['date'] as String;
        _selected = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _dates => _slots.map((s) => s['date'] as String).toSet().toList();
  List<Map<String, dynamic>> get _forDate => _slots.where((s) => s['date'] == _date).toList();
  Map<String, dynamic>? get _selectedSlot {
    for (final s in _slots) {
      if (s['id'] == _selected) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selectedSlot;
    return Scaffold(
      appBar: const OpdAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [ErrorBanner(_error!), const SizedBox(height: 12), SecondaryButton('Try again', onPressed: _load)]),
                )
              : Column(children: [
                  Expanded(
                    child: ListView(padding: const EdgeInsets.all(16), children: [
                      Heading(_clinic!['name'].toString(), subtitle: '${_clinic!['hospital']} · ${_clinic!['room']}'),
                      const SizedBox(height: 14),
                      Panel(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_clinic!['doctor'].toString(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(_clinic!['description'].toString(), style: const TextStyle(color: C.muted)),
                          const SizedBox(height: 6),
                          Text('${_clinic!['days']} · ${_clinic!['open_time']}-${_clinic!['close_time']}',
                              style: const TextStyle(color: C.muted, fontSize: 13)),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      const Text('Choose a date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      if (_slots.isEmpty)
                        const EmptyState(
                            icon: Icons.event_busy,
                            title: 'No sessions available',
                            message: 'There are no open sessions in the next 7 days. Please check again later.')
                      else ...[
                        SizedBox(
                          height: 44,
                          child: ListView(scrollDirection: Axis.horizontal, children: [
                            for (final d in _dates)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(chipDate(d)),
                                  selected: _date == d,
                                  selectedColor: C.brand,
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                      color: _date == d ? Colors.white : C.ink, fontWeight: FontWeight.w700),
                                  showCheckmark: false,
                                  onSelected: (_) => setState(() {
                                    _date = d;
                                    _selected = null;
                                  }),
                                ),
                              ),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        const Text('Available times', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        for (final s in _forDate) _slotTile(s),
                        if (sel != null) ...[
                          const SizedBox(height: 8),
                          Panel(
                            color: C.blueSoft,
                            borderColor: C.blueSoft,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${fullDate(sel['date'])} · ${sel['start_time']}-${sel['end_time']}',
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              const Text('A queue number is assigned only after confirmed booking.',
                                  style: TextStyle(color: C.muted)),
                            ]),
                          ),
                        ],
                      ],
                    ]),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        PrimaryButton(
                          'Continue to Booking  →',
                          onPressed: sel == null
                              ? null
                              : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => BookingScreen(
                                      clinic: _clinic!, slot: sel, patient: widget.bookForPatient))),
                        ),
                        const SizedBox(height: 6),
                        Text(sel == null ? 'Select an available time to continue.' : 'Carries clinic, doctor, date and selected slot context.',
                            style: const TextStyle(color: C.muted, fontSize: 12.5)),
                      ]),
                    ),
                  ),
                ]),
    );
  }

  Widget _slotTile(Map<String, dynamic> s) {
    final full = s['full'] == true;
    final selected = _selected == s['id'];
    final left = s['left'];
    Widget badge;
    if (full) {
      badge = const StatusChip('Full');
    } else if (selected) {
      badge = Text('●  Selected · $left left',
          style: const TextStyle(color: C.brand, fontWeight: FontWeight.w700, fontSize: 13));
    } else {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: C.greenSoft, borderRadius: BorderRadius.circular(20)),
        child: Text('●  Available · $left left',
            style: const TextStyle(color: C.green, fontWeight: FontWeight.w700, fontSize: 12.5)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: full ? null : () => setState(() => _selected = s['id'] as int),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? C.blueSoft : (full ? const Color(0xFFF7F8FA) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? C.brand : C.border, width: selected ? 1.6 : 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${s['start_time']}-${s['end_time']}',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: full ? C.muted : C.ink)),
            badge,
          ]),
        ),
      ),
    );
  }
}
