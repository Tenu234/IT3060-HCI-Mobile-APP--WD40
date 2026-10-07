import 'package:flutter/material.dart';
import '../../models/doctor_queue_item.dart';
import '../../services/doctor_service.dart';
import 'doctor_theme.dart';
import 'consultation_notes_and_dispatch_screen.dart';

class DoctorQueueScreen extends StatefulWidget {
  final VoidCallback? onQueueUpdated;
  final Function(int)? onNavigateTab;
  final String doctorName;

  const DoctorQueueScreen({
    super.key,
    this.onQueueUpdated,
    this.onNavigateTab,
    this.doctorName = 'Dr. RKAM Deshan',
  });

  @override
  State<DoctorQueueScreen> createState() => _DoctorQueueScreenState();
}

class _DoctorQueueScreenState extends State<DoctorQueueScreen> {
  List<DoctorQueueItem> _queue = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, waiting, skipped
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final String _currentRoom = 'Consultation Room 2';

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
                    'Called ${patient.tokenNumber} (${patient.patientName}) into $_currentRoom',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: DoctorTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // Quick Action: Call Next Patient in queue
  void _callNextWaitingPatient() {
    final nextWaiting = _queue.where((p) => p.status == 'waiting' || p.status == 'upcoming').firstOrNull;
    if (nextWaiting != null) {
      _callPatient(nextWaiting);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No waiting patients in queue.'),
          backgroundColor: DoctorTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

    final totalCount = _queue.length;
    final waitingCount = _queue.where((p) => p.status == 'waiting' || p.status == 'upcoming').length;
    final inConsultCount = activePatient != null ? 1 : 0;
    final completedCount = _queue.where((p) => p.status == 'completed').length;

    return RefreshIndicator(
      color: DoctorTheme.primary,
      onRefresh: _loadQueue,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          // 1. Top Greeting Header matching screenshot ("Hi, Priya / How can we help you today?")
          _buildGreetingHeader(),
          const SizedBox(height: 18),

          // 2. Modern Rounded Search Bar matching screenshot ("Search doctors, clinics or symptoms")
          _buildSearchBar(),
          const SizedBox(height: 20),

          // 3. Row of 4 Quick Action Cards matching screenshot
          _buildQuickActionCardsRow(),
          const SizedBox(height: 22),

          // 4. Hero Banner Card matching screenshot ("Your Health Our Priority" style)
          _buildHeroConsultationBanner(activePatient),
          const SizedBox(height: 24),

          // 5. Section Header + 4 Stat Squircle Chips (matching "Top Specialties" row from screenshot)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Queue Breakdown',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: DoctorTheme.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() => _selectedFilter = _selectedFilter == 'all' ? 'waiting' : 'all');
                  _loadQueue();
                },
                child: Text(
                  _selectedFilter == 'all' ? 'Show Waiting Only' : 'Show All',
                  style: const TextStyle(
                    fontSize: 13,
                    color: DoctorTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Stat Squircles (Total, Waiting, In Room, Completed)
          _buildStatSquirclesRow(totalCount, waitingCount, inConsultCount, completedCount),
          const SizedBox(height: 24),

          // 6. Section Header for Patient Queue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Patient Queue (${waitingList.length})',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: DoctorTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DoctorTheme.primaryTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentRoom,
                  style: const TextStyle(
                    color: DoctorTheme.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 7. Queue Items List
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 1. Top Greeting Header
  Widget _buildGreetingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${widget.doctorName.replaceAll('Dr. ', '')}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: DoctorTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Ready for today\'s clinical consultations?',
              style: TextStyle(
                fontSize: 13,
                color: DoctorTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        // Notification bell with alert badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: DoctorTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: DoctorTheme.textPrimary, size: 22),
                onPressed: () {
                  widget.onNavigateTab?.call(1); // Jump to Alerts tab
                },
              ),
              Positioned(
                top: 10,
                right: 11,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF97316), // Orange alert dot from screenshot
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Modern Rounded Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DoctorTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search patient, token or symptoms...',
          hintStyle: const TextStyle(color: DoctorTheme.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: DoctorTheme.textMuted, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: DoctorTheme.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _loadQueue();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        onSubmitted: (val) {
          setState(() => _searchQuery = val);
          _loadQueue();
        },
      ),
    );
  }

  // 3. Row of 4 Quick Action Cards matching screenshot
  Widget _buildQuickActionCardsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionCard(
          icon: Icons.campaign_rounded,
          iconColor: const Color(0xFF0D9488),
          bgColor: const Color(0xFFE6F5F4),
          label: 'Call Next',
          onTap: _callNextWaitingPatient,
        ),
        _buildActionCard(
          icon: Icons.format_list_bulleted_rounded,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
          label: 'All Queue',
          onTap: () {
            setState(() => _selectedFilter = 'all');
            _loadQueue();
          },
        ),
        _buildActionCard(
          icon: Icons.edit_note_rounded,
          iconColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
          label: 'Write Rx',
          onTap: () => widget.onNavigateTab?.call(1),
        ),
        _buildActionCard(
          icon: Icons.analytics_outlined,
          iconColor: const Color(0xFF0284C7),
          bgColor: const Color(0xFFE0F2FE),
          label: 'Daily Logs',
          onTap: () => widget.onNavigateTab?.call(2),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DoctorTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // 4. Hero Banner Card matching screenshot ("Your Health Our Priority" style)
  Widget _buildHeroConsultationBanner(DoctorQueueItem? activePatient) {
    final hasActive = activePatient != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DoctorTheme.bannerStart, DoctorTheme.bannerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A5C6B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Content
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActive ? 'Now in Room 2' : 'Consultation Queue',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F3B45),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasActive
                      ? '${activePatient.tokenNumber} • ${activePatient.patientName}'
                      : 'All systems live. Call next waiting patient.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF265B67),
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // Rounded Action Pill with Arrow button + Finish option
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (hasActive) {
                          _openConsultationNotes(activePatient);
                        } else {
                          _callNextWaitingPatient();
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: DoctorTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    if (hasActive) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _completeConsultation(activePatient),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: DoctorTheme.success.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: DoctorTheme.success, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Finish',
                                style: TextStyle(
                                  color: DoctorTheme.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Right Artwork: Doctor lady portrait avatar
          Expanded(
            flex: 4,
            child: Container(
              height: 110,
              alignment: Alignment.centerRight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A5C6B).withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/images/doctor_lady.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. 4 Stat Squircles (matching "Top Specialties" 4-icon row from screenshot)
  Widget _buildStatSquirclesRow(int total, int waiting, int inConsult, int completed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatSquircle('Total', '$total', Icons.groups_outlined, const Color(0xFF0F766E), const Color(0xFFF0FDFA)),
        _buildStatSquircle('Waiting', '$waiting', Icons.hourglass_empty_rounded, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
        _buildStatSquircle('In Room', '$inConsult', Icons.meeting_room_outlined, const Color(0xFF0284C7), const Color(0xFFF0F9FF)),
        _buildStatSquircle('Done', '$completed', Icons.check_circle_outline_rounded, const Color(0xFF059669), const Color(0xFFECFDF5)),
      ],
    );
  }

  Widget _buildStatSquircle(String label, String count, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 7. Patient Queue Card (Modern styling)
  Widget _buildQueueItemCard(DoctorQueueItem item) {
    final isSkipped = item.status == 'skipped';
    final isWaiting = item.status == 'waiting' || item.status == 'upcoming';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                // Token pill badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSkipped ? DoctorTheme.warningLight : DoctorTheme.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSkipped ? DoctorTheme.warning : DoctorTheme.primaryLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    item.tokenNumber,
                    style: TextStyle(
                      color: isSkipped ? const Color(0xFF92400E) : DoctorTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: DoctorTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            item.timeSlot,
                            style: const TextStyle(color: DoctorTheme.textSecondary, fontSize: 11),
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
                                fontSize: 9,
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
                ),
                child: Text(
                  'Complaint: ${item.symptoms}',
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
                    ),
                    onPressed: () => _recallPatient(item),
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    label: const Text('Recall to Queue', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ] else if (isWaiting) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: DoctorTheme.warning),
                    onPressed: () => _skipPatient(item),
                    icon: const Icon(Icons.person_off_rounded, size: 15),
                    label: const Text('Skip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DoctorTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _callPatient(item),
                    icon: const Icon(Icons.campaign_rounded, size: 16),
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
            decoration: const BoxDecoration(
              color: DoctorTheme.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.done_all_rounded, size: 36, color: DoctorTheme.primary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Queue is Clear',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DoctorTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'No patients waiting in queue.',
            style: TextStyle(color: DoctorTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
