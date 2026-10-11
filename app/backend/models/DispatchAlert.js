const mongoose = require('mongoose');

const dispatchAlertSchema = new mongoose.Schema(
  {
    doctorId:     { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    doctorName:   { type: String, default: 'Dr. RKAM Deshan' },
    tokenNumber:  { type: String, required: true },
    patientName:  { type: String, default: 'Patient' },
    roomNumber:   { type: String, default: 'Consultation Room 2' },
    message:      { type: String, required: true },
    alertType:    {
      type: String,
      enum: ['queue_call', 'lab_dispatch', 'pharmacy', 'urgent_call'],
      default: 'queue_call',
    },
    status:       {
      type: String,
      enum: ['active', 'dismissed'],
      default: 'active',
    },
    priority:     {
      type: String,
      enum: ['normal', 'urgent'],
      default: 'normal',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('DispatchAlert', dispatchAlertSchema);
