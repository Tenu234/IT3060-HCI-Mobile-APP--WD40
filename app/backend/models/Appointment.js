const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema(
  {
    patientId:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    hospitalName: { type: String, required: true },
    opdName:      { type: String, required: true },
    doctorName:   { type: String, required: true },
    date:         { type: String, required: true },
    timeSlot:     { type: String, required: true },
    status:       { type: String, enum: ['upcoming', 'completed', 'cancelled'], default: 'upcoming' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Appointment', appointmentSchema);
