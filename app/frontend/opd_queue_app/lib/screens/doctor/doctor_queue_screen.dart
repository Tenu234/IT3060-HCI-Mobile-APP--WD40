import 'package:flutter/material.dart';
import '../../models/doctor_queue_item.dart';
import '../../services/doctor_service.dart';
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
  String _selectedFilter = 'all'; // all, waiting, in_consultation, skipped
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
          SnackBar(content: Text('Error loading queue: $e'), backgroundColor: Colors.red),
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
            content: Text('📢 Token ${patient.tokenNumber} (${patient.patientName}) called into $_currentRoom'),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 3),
          ),
        );
        _loadQueue();
        widget.onQueueUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
            content: Text('✅ Consultation completed for ${patient.tokenNumber}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadQueue();
        widget.onQueueUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // DELETE: Skip / Dismiss absent patient from active queue
  Future<void> _skipPatient(DoctorQueueItem patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dismiss / Skip Patient?'),
        content: Text(
          'Mark ${patient.tokenNumber} (${patient.patientName}) as absent/skipped from active queue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Skip Patient', style: TextStyle(color: Colors.white)),
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
            content: Text('Patient ${patient.tokenNumber} moved to skipped list.'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadQueue();
        widget.onQueueUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
            content: Text('Patient ${patient.tokenNumber} recalled to waiting queue.'),
            backgroundColor: Colors.blue,
          ),
        );
        _loadQueue();
        widget.onQueueUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
      onRefresh: _loadQueue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Room & Doctor Banner
          _buildRoomHeader(),
          const SizedBox(height: 16),

          // Prominent "NOW SERVING" Active Card (HCI Key Visibility)
          if (activePatient != null) ...[
            _buildActiveConsultationCard(activePatient),
            const SizedBox(height: 20),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_selectedFilter == 'all')
                Text(
                  'Total: ${_queue.length}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Queue Items List
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
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
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.meeting_room, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _currentRoom,
                    dropdownColor: Colors.teal.shade800,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Colors.greenAccent),
                    SizedBox(width: 6),
                    Text('ON DUTY', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'General OPD • Today\'s Live Queue',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveConsultationCard(DoctorQueueItem patient) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle, color: Colors.teal, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'CURRENTLY IN ROOM ($_currentRoom)',
                      style: TextStyle(
                        color: Colors.teal.shade800,
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
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'IN CONSULTATION',
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
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        patient.tokenNumber,
                        style: TextStyle(
                          color: Colors.teal.shade900,
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
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          if (patient.patientPhone != null)
                            Text(
                              'Phone: ${patient.patientPhone}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          if (patient.symptoms.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Symptoms: "${patient.symptoms}"',
                                style: const TextStyle(color: Colors.black87, fontStyle: FontStyle.italic, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          side: const BorderSide(color: Colors.teal),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _openConsultationNotes(patient),
                        icon: const Icon(Icons.edit_note, size: 20),
                        label: const Text('Add Notes / Rx'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _completeConsultation(patient),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text('Complete Turn'),
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
        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by Token or Patient name...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadQueue();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (val) {
            setState(() => _searchQuery = val);
            _loadQueue();
          },
        ),
        const SizedBox(height: 10),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'All Patients'),
              _buildFilterChip('waiting', 'Waiting Only'),
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
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.teal,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    color: isSkipped ? Colors.orange.shade100 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSkipped ? Colors.orange : Colors.teal.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    item.tokenNumber,
                    style: TextStyle(
                      color: isSkipped ? Colors.orange.shade900 : Colors.teal.shade900,
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            item.timeSlot,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSkipped ? Colors.orange.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSkipped ? Colors.orange.shade800 : Colors.blue.shade800,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Reason / Symptoms: ${item.symptoms}',
                  style: TextStyle(color: Colors.grey[800], fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isSkipped) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    onPressed: () => _recallPatient(item),
                    icon: const Icon(Icons.replay, size: 18),
                    label: const Text('Recall to Queue'),
                  ),
                ] else if (isWaiting) ...[
                  // DELETE action in CRUD: Skip/Dismiss absent patient
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
                    onPressed: () => _skipPatient(item),
                    icon: const Icon(Icons.person_off, size: 16),
                    label: const Text('Skip / Absent'),
                  ),
                  const SizedBox(width: 8),
                  // UPDATE action in CRUD: Call Next Patient
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () => _callPatient(item),
                    icon: const Icon(Icons.campaign, size: 18),
                    label: const Text('Call Patient'),
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
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 56, color: Colors.teal.shade300),
          const SizedBox(height: 12),
          const Text(
            'No patients currently in this list',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull down to refresh or change the filter tab.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
