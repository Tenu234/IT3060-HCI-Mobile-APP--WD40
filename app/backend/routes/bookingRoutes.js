const express = require('express');
const router = express.Router();
const Appointment = require('../models/Appointment');
const Booking = require('../models/Booking');

// GET all bookings / queue entries for staff
router.get('/', async (req, res) => {
  try {
    const appointments = await Appointment.find()
      .populate('patientId', 'name phone nic email')
      .sort({ createdAt: -1 });

    const mapped = appointments.map((apt, index) => {
      const obj = apt.toObject();
      return {
        _id: obj._id,
        patientName: obj.patientName || (obj.patientId ? obj.patientId.name : 'Patient'),
        patientPhone: obj.patientPhone || (obj.patientId ? obj.patientId.phone : '0771234567'),
        doctorName: obj.doctorName || 'Dr. RKAM Deshan',
        roomNumber: obj.roomNumber || 'Consultation Room 2',
        tokenNumber: obj.tokenNumber || `A-${101 + index}`,
        status: obj.status || 'waiting',
        createdAt: obj.createdAt || new Date(),
      };
    });
    res.json(mapped);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST create a new walk-in booking
router.post('/', async (req, res) => {
  try {
    const count = await Appointment.countDocuments();
    const tokenNumber = req.body.tokenNumber || `A-${101 + count}`;
    const apt = await Appointment.create({
      patientName: req.body.patientName,
      patientPhone: req.body.patientPhone || '',
      doctorName: req.body.doctorName || 'Dr. RKAM Deshan',
      roomNumber: req.body.roomNumber || 'Consultation Room 2',
      tokenNumber,
      status: req.body.status || 'entered_opd',
      hospitalName: req.body.hospitalName || 'City General Hospital',
      opdName: req.body.opdName || 'General OPD',
      date: new Date().toISOString().split('T')[0],
      timeSlot: 'Walk-in',
    });

    res.status(201).json({
      _id: apt._id,
      patientName: apt.patientName,
      patientPhone: apt.patientPhone,
      doctorName: apt.doctorName,
      roomNumber: apt.roomNumber,
      tokenNumber: apt.tokenNumber,
      status: apt.status,
      createdAt: apt.createdAt,
    });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// PUT update a booking / status
router.put('/:id', async (req, res) => {
  try {
    const updateData = { ...req.body };
    const updated = await Appointment.findByIdAndUpdate(req.params.id, updateData, { new: true });
    if (!updated) {
      const updatedBooking = await Booking.findByIdAndUpdate(req.params.id, updateData, { new: true });
      if (!updatedBooking) return res.status(404).json({ message: 'Booking not found' });
      return res.json(updatedBooking);
    }
    res.json({
      _id: updated._id,
      patientName: updated.patientName,
      patientPhone: updated.patientPhone,
      doctorName: updated.doctorName,
      roomNumber: updated.roomNumber,
      tokenNumber: updated.tokenNumber,
      status: updated.status,
      createdAt: updated.createdAt,
    });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DELETE a booking
router.delete('/:id', async (req, res) => {
  try {
    await Appointment.findByIdAndDelete(req.params.id);
    await Booking.findByIdAndDelete(req.params.id);
    res.json({ message: 'Booking deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
