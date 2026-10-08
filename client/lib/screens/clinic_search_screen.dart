import 'dart:async';
import 'package:flutter/material.dart';
import '../router.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'my_appointments_screen.dart';
import 'profile_screen.dart';
import 'slots_screen.dart';

/// OPD Search ("Find an OPD clinic").
/// When [bookForPatient] is set (staff flow) the chosen slot books a token for that patient.
class ClinicSearchScreen extends StatefulWidget {
  final Map<String, dynamic>? bookForPatient;
  final bool savedOnly;
  final bool showAccountMenu;
  final int refreshKey;
  const ClinicSearchScreen({
    super.key,
    this.bookForPatient,
    this.savedOnly = false,
    this.showAccountMenu = true,
    this.refreshKey = 0,
  });
  @override
  State<ClinicSearchScreen> createState() => _ClinicSearchScreenState();
}

class _ClinicSearchScreenState extends State<ClinicSearchScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _clinics = [];
  List<String> _districtOptions = [];
  List<String> _clinicOptions = [];
  Set<String> _districts = {};
  Set<String> _types = {};
  bool _openToday = false;
  bool _savedOnly = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _savedOnly = widget.savedOnly;
    _loadFilters();
    _search();
  }

  @override
  void didUpdateWidget(covariant ClinicSearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.savedOnly && oldWidget.refreshKey != widget.refreshKey) {
      _search();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final r = await Api.i.get('/clinics/filters');
      if (!mounted) return;
      setState(() {
        _districtOptions = List<String>.from(r['districts'] as List);
        _clinicOptions = List<String>.from(r['clinics'] as List);
      });
    } catch (_) {}
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Api.i.get('/clinics', {
        'q': _q.text.trim(),
        'district': _districts.join(','),
        'clinic': _types.join(','),
        'openToday': _openToday.toString(),
        'saved': _savedOnly.toString(),
      });
      if (!mounted) return;
      setState(() => _clinics = (r['clinics'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onQuery(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<Set<String>?> _pickMany(
      String title, List<String> options, Set<String> selected) {
    final temp = {...selected};
    return showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (final o in options)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(o),
                      value: temp.contains(o),
                      onChanged: (v) =>
                          setS(() => v == true ? temp.add(o) : temp.remove(o)),
                    ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: SecondaryButton('Clear',
                            onPressed: () => Navigator.pop(ctx, <String>{}))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: PrimaryButton('Apply',
                            onPressed: () => Navigator.pop(ctx, temp))),
                  ]),
                ]),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSave(Map<String, dynamic> c) async {
    final saved = c['saved'] == true;
    try {
      if (saved) {
        await Api.i.delete('/clinics/${c['id']}/favorite');
      } else {
        await Api.i.post('/clinics/${c['id']}/favorite');
      }
      if (!mounted) return;
      setState(() => c['saved'] = !saved);
      snack(context, saved ? 'Removed from saved clinics' : 'Clinic saved');
      if (_savedOnly) _search();
    } on ApiException catch (e) {
      if (mounted) snack(context, e.message, error: true);
    }
  }

  void _clearFilters() {
    _q.clear();
    _districts = {};
    _types = {};
    _openToday = false;
    _savedOnly = widget.savedOnly;
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final staffMode = widget.bookForPatient != null;
    final filterText =
        'District: ${_districts.isEmpty ? 'All districts' : _districts.join(' · ')}  ·  Clinic: ${_types.isEmpty ? 'All clinics' : _types.join(' · ')}';
    return Scaffold(
      appBar: OpdAppBar(
        subtitle: staffMode
            ? 'Booking for ${widget.bookForPatient!['full_name']}'
            : 'Patient Services',
        actions: [
          if (!staffMode && widget.showAccountMenu)
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle_outlined, color: C.muted),
              onSelected: (v) {
                if (v == 'appts') {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const MyAppointmentsScreen()));
                } else if (v == 'profile') {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()));
                } else {
                  doLogout(context);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'appts', child: Text('My appointments')),
                PopupMenuItem(value: 'profile', child: Text('My profile')),
                PopupMenuItem(value: 'logout', child: Text('Log out')),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _search,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Heading('Find an OPD clinic',
              subtitle:
                  'Search government hospital clinics and available sessions.'),
          const SizedBox(height: 14),
          const Text('Search', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _q,
            onChanged: _onQuery,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Search hospital, clinic or doctor',
              prefixIcon: const Icon(Icons.search, color: C.muted),
              suffixIcon: _q.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, color: C.muted),
                      onPressed: () {
                        _q.clear();
                        _search();
                      }),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilterPill(
              label: _districts.isEmpty
                  ? 'All districts'
                  : '${_districts.length} district(s)',
              active: _districts.isNotEmpty,
              onTap: () async {
                final r =
                    await _pickMany('Districts', _districtOptions, _districts);
                if (r != null) {
                  _districts = r;
                  _search();
                }
              },
            ),
            FilterPill(
              label: _types.isEmpty
                  ? 'All clinics'
                  : '${_types.length} clinic type(s)',
              active: _types.isNotEmpty,
              onTap: () async {
                final r =
                    await _pickMany('Clinic types', _clinicOptions, _types);
                if (r != null) {
                  _types = r;
                  _search();
                }
              },
            ),
            FilterPill(
              label: 'Open today',
              active: _openToday,
              dot: C.green,
              onTap: () {
                _openToday = !_openToday;
                _search();
              },
            ),
            if (!staffMode && !widget.savedOnly)
              FilterPill(
                label: 'Saved',
                active: _savedOnly,
                dot: C.red,
                onTap: () {
                  _savedOnly = !_savedOnly;
                  _search();
                },
              ),
          ]),
          const SizedBox(height: 10),
          Text(filterText,
              style: const TextStyle(color: C.muted, fontSize: 12.5)),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()))
          else if (_error != null) ...[
            ErrorBanner(_error!),
            const SizedBox(height: 12),
            SecondaryButton('Try again', onPressed: _search),
          ] else if (_clinics.isEmpty)
            EmptyState(
              icon: Icons.search_off,
              title: 'No clinics found',
              message: 'Try a different search or clear your filters.',
              actionLabel: 'Clear filters',
              onAction: _clearFilters,
            )
          else ...[
            Text(
                '${_clinics.length} clinic${_clinics.length == 1 ? '' : 's'} found',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final c in _clinics) _card(c, staffMode),
          ],
        ]),
      ),
    );
  }

  Widget _card(Map<String, dynamic> c, bool staffMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(c['hospital'].toString(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            if (!staffMode)
              InkWell(
                onTap: () => _toggleSave(c),
                child: Icon(
                    c['saved'] == true ? Icons.favorite : Icons.favorite_border,
                    color: c['saved'] == true ? C.red : C.muted,
                    size: 22),
              ),
          ]),
          const SizedBox(height: 4),
          Text('${c['name']} · ${c['district']}',
              style:
                  const TextStyle(color: C.brand, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${c['open_time']}-${c['close_time']}',
                style: const TextStyle(color: C.muted, fontSize: 13)),
            Text(
                c['open_today'] == true
                    ? '${c['waiting']} waiting'
                    : 'No session today',
                style: TextStyle(
                    color: c['open_today'] == true ? C.amber : C.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          SecondaryButton('View Slots',
              fill: C.blueSoft,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SlotsScreen(
                      clinicId: c['id'] as int,
                      bookForPatient: widget.bookForPatient)))),
        ]),
      ),
    );
  }
}
