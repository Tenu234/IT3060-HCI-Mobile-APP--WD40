const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema(
  {
    patientId:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    hospitalName: { type: String, required: true },
    opdName:      { type: String, required: true },
    doctorName:   { type: String, required: true },
    date:         { type: String, required: true },
    timeSlot:     { type: String, required: true },
    tokenNumber:  { type: String, default: '' },
    patientName:  { type: String, default: '' },
    roomNumber:   { type: String, default: 'Consultation Room 2' },
    symptoms:     { type: String, default: '' },
    status:       {
      type: String,
      enum: ['upcoming', 'waiting', 'in_consultation', 'completed', 'skipped', 'cancelled'],
      default: 'waiting',
    },
    clinicalNotes: { type: String, default: '' },
    diagnosis:     { type: String, default: '' },
    prescription:  { type: String, default: '' },
    consultationStartTime: { type: Date },
    consultationEndTime:   { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Appointment', appointmentSchema);
