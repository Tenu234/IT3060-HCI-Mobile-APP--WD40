import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'patient_dashboard.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final UserModel user;
  final String hospitalName;
  final String opdName;
  final String doctorName;
  final String date;
  final String timeSlot;
  final String appointmentId;
  final int queueNumber;

  const BookingConfirmationScreen({
    super.key,
    required this.user,
    required this.hospitalName,
    required this.opdName,
    required this.doctorName,
    required this.date,
    required this.timeSlot,
    required this.appointmentId,
    required this.queueNumber,
  });

  int get _estimatedWaitMins => queueNumber * 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => PatientDashboard(user: user)),
            (_) => false,
          ),
        ),
        title: const Text('Booking Confirmed'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF2196F3),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Green check icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green.shade200, width: 2),
                    ),
                    child: Icon(Icons.check_circle_outline,
                        color: Colors.green.shade600, size: 36),
                  ),
                  const SizedBox(height: 16),

                  const Text('Appointment Confirmed!',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Your booking reference has been sent via SMS.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 24),

                  // Booking card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hospital + OPD
                        Text('$hospitalName - $opdName',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('APPT ID: $appointmentId',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(height: 16),

                        // Queue number box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text('Queue No: $queueNumber',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1565C0))),
                              const SizedBox(height: 4),
                              Text('Est. Waiting Time: ~$_estimatedWaitMins mins',
                                  style: const TextStyle(
                                      color: Color(0xFF1976D2), fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Date & Time
                        Row(
                          children: [
                            Expanded(child: _infoCol('DATE', date)),
                            Expanded(child: _infoCol('TIME', timeSlot)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _infoCol('DOCTOR', doctorName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add to Calendar
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: const Text('Add to Calendar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Calendar integration coming soon.')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Download PDF
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('PDF download coming soon.')),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_outlined,
                            color: Color(0xFF1565C0), size: 18),
                        SizedBox(width: 6),
                        Text('Download PDF Receipt',
                            style: TextStyle(
                                color: Color(0xFF1565C0),
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PatientDashboard(user: user)),
                  (_) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Go to My Appointments',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
