const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema(
  {
    patientId:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: false },
    hospitalName: { type: String, default: 'City General Hospital' },
    opdName:      { type: String, default: 'General OPD' },
    doctorName:   { type: String, required: true },
    date:         { type: String, required: true },
    timeSlot:     { type: String, required: true },
    tokenNumber:  { type: String, default: '' },
    patientName:  { type: String, default: '' },
    patientPhone: { type: String, default: '' },
    roomNumber:   { type: String, default: 'Consultation Room 2' },
    symptoms:     { type: String, default: '' },
    status:       {
      type: String,
      enum: ['upcoming', 'entered_opd', 'waiting_room', 'waiting', 'in_consultation', 'completed', 'skipped', 'absent', 'cancelled'],
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
