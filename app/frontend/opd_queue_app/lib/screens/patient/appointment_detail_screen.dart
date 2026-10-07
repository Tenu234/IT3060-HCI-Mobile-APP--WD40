import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;
  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late AppointmentModel _apt;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apt = widget.appointment;
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isLoading = true);
    await AppointmentService.cancelAppointment(_apt.id);
    setState(() {
      _apt = AppointmentModel(
        id: _apt.id,
        hospitalName: _apt.hospitalName,
        opdName: _apt.opdName,
        doctorName: _apt.doctorName,
        date: _apt.date,
        timeSlot: _apt.timeSlot,
        status: 'cancelled',
      );
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled.')),
      );
    }
  }

  Future<void> _reschedule() async {
    String? newDate;
    String? newSlot;

    final slots = ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reschedule Appointment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(newDate ?? 'Pick new date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      setModal(() => newDate =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Select new time slot',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: slots.map((s) => ChoiceChip(
                    label: Text(s),
                    selected: newSlot == s,
                    onSelected: (_) => setModal(() => newSlot = s),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: (newDate != null && newSlot != null)
                        ? () => Navigator.pop(ctx)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm Reschedule'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (newDate != null && newSlot != null) {
      setState(() => _isLoading = true);
      await AppointmentService.rescheduleAppointment(_apt.id, newDate!, newSlot!);
      setState(() {
        _apt = AppointmentModel(
          id: _apt.id,
          hospitalName: _apt.hospitalName,
          opdName: _apt.opdName,
          doctorName: _apt.doctorName,
          date: newDate!,
          timeSlot: newSlot!,
          status: 'upcoming',
        );
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment rescheduled.')),
        );
      }
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUpcoming = _apt.status == 'upcoming';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isUpcoming ? Colors.teal.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUpcoming ? Colors.teal.shade200 : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _apt.status.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUpcoming ? Colors.teal : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _infoRow(Icons.local_hospital_outlined, 'Hospital', _apt.hospitalName),
                          const Divider(),
                          _infoRow(Icons.medical_services_outlined, 'OPD', _apt.opdName),
                          const Divider(),
                          _infoRow(Icons.person_outline, 'Doctor', _apt.doctorName),
                          const Divider(),
                          _infoRow(Icons.calendar_today_outlined, 'Date', _apt.date),
                          const Divider(),
                          _infoRow(Icons.access_time_outlined, 'Time', _apt.timeSlot),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  if (isUpcoming) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: const Text('Reschedule'),
                        onPressed: _reschedule,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Appointment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _cancel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
