const Appointment = require('../models/Appointment');
const User = require('../models/User');

// GET /api/appointments — get logged-in patient's appointments
exports.getMyAppointments = async (req, res) => {
  try {
    let appointments = await Appointment.find({ patientId: req.user.id }).sort({ createdAt: -1 });

    // Backfill tokenNumber if missing
    for (let i = 0; i < appointments.length; i++) {
      if (!appointments[i].tokenNumber) {
        appointments[i].tokenNumber = `A-${101 + i}`;
        await appointments[i].save();
      }
    }

    res.json(appointments);
  } catch (err) {
    console.error('getMyAppointments error:', err);
    res.status(500).json({ message: 'Server error.' });
  }
};

// POST /api/appointments — book a new appointment
exports.bookAppointment = async (req, res) => {
  try {
    const { hospitalName, opdName, doctorName, date, timeSlot } = req.body;

    const user = await User.findById(req.user.id);
    const patientName = user ? user.name : 'Patient';
    const patientPhone = user ? (user.phone || '') : '';

    const count = await Appointment.countDocuments();
    const tokenNumber = `A-${101 + count}`;

    const appointment = await Appointment.create({
      patientId: req.user.id,
      patientName,
      patientPhone,
      hospitalName: hospitalName || 'City General Hospital',
      opdName: opdName || 'General OPD',
      doctorName: doctorName || 'Dr. RKAM Deshan',
      date: date || new Date().toISOString().split('T')[0],
      timeSlot: timeSlot || '09:00 AM',
      tokenNumber,
      roomNumber: 'Consultation Room 2',
      status: 'waiting',
    });
    res.status(201).json(appointment);
  } catch (err) {
    console.error('bookAppointment error:', err);
    res.status(500).json({ message: 'Server error.' });
  }
};

// PATCH /api/appointments/:id/cancel
exports.cancelAppointment = async (req, res) => {
  try {
    const apt = await Appointment.findOneAndUpdate(
      { _id: req.params.id, patientId: req.user.id },
      { status: 'cancelled' },
      { new: true }
    );
    if (!apt) return res.status(404).json({ message: 'Appointment not found.' });
    res.json(apt);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
};

// PATCH /api/appointments/:id/reschedule
exports.rescheduleAppointment = async (req, res) => {
  try {
    const { date, timeSlot } = req.body;
    const apt = await Appointment.findOneAndUpdate(
      { _id: req.params.id, patientId: req.user.id },
      { date, timeSlot, status: 'upcoming' },
      { new: true }
    );
    if (!apt) return res.status(404).json({ message: 'Appointment not found.' });
    res.json(apt);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
};
