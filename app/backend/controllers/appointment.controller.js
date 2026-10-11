const Appointment = require('../models/Appointment');

// GET /api/appointments — get logged-in patient's appointments
exports.getMyAppointments = async (req, res) => {
  try {
    const appointments = await Appointment.find({ patientId: req.user.id }).sort({ createdAt: -1 });
    res.json(appointments);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
};

// POST /api/appointments — book a new appointment
exports.bookAppointment = async (req, res) => {
  try {
    const { hospitalName, opdName, doctorName, date, timeSlot } = req.body;
    const appointment = await Appointment.create({
      patientId: req.user.id,
      hospitalName,
      opdName,
      doctorName,
      date,
      timeSlot,
    });
    res.status(201).json(appointment);
  } catch (err) {
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
