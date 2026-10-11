const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  patientName: {
    type: String,
    required: true,
  },
  patientPhone: {
    type: String,
    required: true,
  },
  doctorName: {
    type: String,
    required: true,
  },
  roomNumber: {
    type: String,
    default: 'Consultation Room 2',
  },
  tokenNumber: {
    type: String,
    default: '',
  },
  status: {
    type: String,
    enum: ['upcoming', 'entered_opd', 'waiting_room', 'waiting', 'in_consultation', 'completed', 'skipped', 'absent', 'cancelled'],
    default: 'entered_opd',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Booking', bookingSchema);
