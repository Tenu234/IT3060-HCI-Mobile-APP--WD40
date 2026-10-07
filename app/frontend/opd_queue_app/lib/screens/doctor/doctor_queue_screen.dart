import 'package:flutter/material.dart';
import '../../models/doctor_queue_item.dart';
import '../../services/doctor_service.dart';
import 'doctor_theme.dart';
import 'consultation_notes_and_dispatch_screen.dart';

class DoctorQueueScreen extends StatefulWidget {
  final VoidCallback? onQueueUpdated;
  const DoctorQueueScreen({super.key, this.onQueueUpdated});

  @override
  State<DoctorQueueScreen> createState() => _DoctorQueueScreenState();
}

class _DoctorQueueScreenState extends State<DoctorQueueScreen> {
  List<DoctorQueueItem> _queue = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, waiting, skipped
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _currentRoom = 'Consultation Room 2';

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final data = await DoctorService.getDailyQueue(
        status: _selectedFilter,
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _queue = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading queue: $e'),
            backgroundColor: DoctorTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // UPDATE: Call Patient to "In Consultation"
  Future<void> _callPatient(DoctorQueueItem patient) async {
    try {
      await DoctorService.updatePatientStatus(
        patient.id,
        'in_consultation',
        roomNumber: _currentRoom,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Called Token ${patient.tokenNumber} (${patient.patientName}) to $_currentRoom',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: DoctorTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        _loadQueue();
        widget.onQueueUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DoctorTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // UPDATE: Mark "Completed"
  Future<void> _completeConsultation(DoctorQueueItem patient) async {
    try {
      await DoctorService.updatePatientStatus(patient.id, 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consultation completed for ${patient.tokenNumber}'),
            backgroundColor: DoctorTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadQueue();
        widget.onQueueUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DoctorTheme.danger),
        );
      }
    }
  }

  // DELETE: Skip / Dismiss absent patient from active queue
  Future<void> _skipPatient(DoctorQueueItem patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_off_rounded, color: DoctorTheme.warning, size: 22),
            SizedBox(width: 8),
            Text('Dismiss Patient?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Mark ${patient.tokenNumber} (${patient.patientName}) as absent / skipped from immediate queue?',
          style: const TextStyle(color: DoctorTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: DoctorTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorTheme.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Skip Patient'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DoctorService.skipPatient(patient.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${patient.tokenNumber} moved to skipped list.'),
            backgroundColor: DoctorTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadQueue();
        widget.onQueueUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DoctorTheme.danger),
        );
      }
    }
  }

  // Recall skipped patient
  Future<void> _recallPatient(DoctorQueueItem patient) async {
    try {
      await DoctorService.recallPatient(patient.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${patient.tokenNumber} recalled to waiting queue.'),
            backgroundColor: DoctorTheme.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadQueue();
        widget.onQueueUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DoctorTheme.danger),
        );
      }
    }
  }

  void _openConsultationNotes(DoctorQueueItem patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationNotesAndDispatchScreen(patientToConsult: patient),
      ),
    ).then((_) {
      _loadQueue();
      widget.onQueueUpdated?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activePatient = _queue.where((p) => p.status == 'in_consultation').firstOrNull;
    final waitingList = _queue.where((p) => p.status != 'in_consultation').toList();

    return RefreshIndicator(
      color: DoctorTheme.primary,
      onRefresh: _loadQueue,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Room & Status Header
          _buildRoomHeader(),
          const SizedBox(height: 16),

          // Prominent "NOW SERVING" Active Card (HCI Key Visibility)
          if (activePatient != null) ...[
            _buildActiveConsultationCard(activePatient),
            const SizedBox(height: 18),
          ],

          // Search and Filter Bar
          _buildSearchAndFilters(),
          const SizedBox(height: 16),

          // Queue List Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Waiting Queue (${waitingList.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DoctorTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DoctorTheme.primaryTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: ${_queue.length}',
                  style: const TextStyle(
                    color: DoctorTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Queue Items List
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: DoctorTheme.primary),
              ),
            )
          else if (waitingList.isEmpty)
            _buildEmptyQueueState()
          else
            ...waitingList.map((item) => _buildQueueItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildRoomHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DoctorTheme.primary, Color(0xFF236E7F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DoctorTheme.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.meeting_room_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: _currentRoom,
                    dropdownColor: DoctorTheme.primaryDark,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Consultation Room 1', child: Text('Room 1')),
                      DropdownMenuItem(value: 'Consultation Room 2', child: Text('Room 2 (Assigned)')),
                      DropdownMenuItem(value: 'Consultation Room 3', child: Text('Room 3')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _currentRoom = val);
                    },
                  ),
                  const Text(
                    'General OPD • Live Consultation',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: Color(0xFF34D399)),
                SizedBox(width: 6),
                Text(
                  'IN SESSION',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveConsultationCard(DoctorQueueItem patient) {
    return Container(
      decoration: DoctorTheme.cardDecoration(
        borderColor: DoctorTheme.primaryLight,
        bgColor: Colors.white,
      ),
      child: Column(
        children: [
          // Banner Top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: DoctorTheme.primaryTint,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_pin_circle_rounded, color: DoctorTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'CURRENTLY IN CONSULTATION',
                      style: TextStyle(
                        color: DoctorTheme.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DoctorTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Big Token Badge
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: DoctorTheme.primaryTint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DoctorTheme.primaryLight.withValues(alpha: 0.4)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        patient.tokenNumber,
                        style: const TextStyle(
                          color: DoctorTheme.primaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.patientName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: DoctorTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (patient.patientPhone != null)
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 13, color: DoctorTheme.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  patient.patientPhone!,
                                  style: const TextStyle(color: DoctorTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          if (patient.symptoms.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: DoctorTheme.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Complaint: "${patient.symptoms}"',
                                  style: const TextStyle(
                                    color: DoctorTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: DoctorTheme.border),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DoctorTheme.primary,
                          side: const BorderSide(color: DoctorTheme.primary, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _openConsultationNotes(patient),
                        icon: const Icon(Icons.edit_note_rounded, size: 19),
                        label: const Text('Add Notes / Rx', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DoctorTheme.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _completeConsultation(patient),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
                        label: const Text('Complete Turn', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Modern Search input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DoctorTheme.border),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search token or patient name...',
              hintStyle: const TextStyle(color: DoctorTheme.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: DoctorTheme.textMuted, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: DoctorTheme.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _loadQueue();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onSubmitted: (val) {
              setState(() => _searchQuery = val);
              _loadQueue();
            },
          ),
        ),
        const SizedBox(height: 10),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'All Active Patients'),
              _buildFilterChip('waiting', 'Waiting Queue'),
              _buildFilterChip('skipped', 'Skipped / Absent'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : DoctorTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        selectedColor: DoctorTheme.primary,
        side: BorderSide(
          color: isSelected ? DoctorTheme.primary : DoctorTheme.border,
        ),
        showCheckmark: false,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
          _loadQueue();
        },
      ),
    );
  }

  Widget _buildQueueItemCard(DoctorQueueItem item) {
    final isSkipped = item.status == 'skipped';
    final isWaiting = item.status == 'waiting' || item.status == 'upcoming';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: DoctorTheme.cardDecoration(
        borderColor: isSkipped ? DoctorTheme.warning.withValues(alpha: 0.3) : DoctorTheme.border,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Token number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSkipped ? DoctorTheme.warningLight : DoctorTheme.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSkipped ? DoctorTheme.warning : DoctorTheme.primaryLight.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    item.tokenNumber,
                    style: TextStyle(
                      color: isSkipped ? const Color(0xFF92400E) : DoctorTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: DoctorTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 13, color: DoctorTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            item.timeSlot,
                            style: const TextStyle(color: DoctorTheme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSkipped ? DoctorTheme.warningLight : DoctorTheme.infoLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSkipped ? const Color(0xFF92400E) : DoctorTheme.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.symptoms.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DoctorTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DoctorTheme.border.withValues(alpha: 0.6)),
                ),
                child: Text(
                  'Reason: ${item.symptoms}',
                  style: const TextStyle(color: DoctorTheme.textSecondary, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 10),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isSkipped) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: DoctorTheme.info,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: () => _recallPatient(item),
                    icon: const Icon(Icons.replay_rounded, size: 17),
                    label: const Text('Recall to Queue', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ] else if (isWaiting) ...[
                  // DELETE action in CRUD: Skip/Dismiss absent patient
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DoctorTheme.warning,
                      side: const BorderSide(color: DoctorTheme.warning),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: () => _skipPatient(item),
                    icon: const Icon(Icons.person_off_rounded, size: 15),
                    label: const Text('Skip / Absent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  // UPDATE action in CRUD: Call Next Patient
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DoctorTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _callPatient(item),
                    icon: const Icon(Icons.campaign_rounded, size: 17),
                    label: const Text('Call Patient', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueueState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DoctorTheme.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.done_all_rounded, size: 40, color: DoctorTheme.primary),
          ),
          const SizedBox(height: 14),
          const Text(
            'Queue is Clear',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: DoctorTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'No patients waiting under this filter tab.',
            style: TextStyle(color: DoctorTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
