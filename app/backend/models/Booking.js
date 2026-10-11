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
    required: true,
  },
  status: {
    type: String,
    enum: ['entered_opd', 'waiting_room', 'in_consultation', 'completed', 'absent', 'cancelled'],
    default: 'entered_opd',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Booking', bookingSchema);
