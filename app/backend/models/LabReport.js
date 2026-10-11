const mongoose = require('mongoose');

const labReportSchema = new mongoose.Schema(
  {
    patientId:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    reportName:  { type: String, required: true },
    category:    { type: String, enum: ['Blood Test', 'X-Ray', 'ECG', 'Urine Test', 'Scan', 'Other'], default: 'Other' },
    testDate:    { type: String, required: true },
    notes:       { type: String, default: '' },
    documentUrl: { type: String, default: '' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('LabReport', labReportSchema);
