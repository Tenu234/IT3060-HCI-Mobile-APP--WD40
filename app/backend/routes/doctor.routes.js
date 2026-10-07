const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const {
  getDailyQueue,
  updatePatientStatus,
  saveConsultationNotes,
  skipPatient,
  recallPatient,
  getDoctorSummary,
  createDispatchAlert,
  getDispatchAlerts,
  deleteDispatchAlert,
} = require('../controllers/doctor.controller');

// Optional/flexible auth middleware for Doctor routes
const doctorAuth = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (token) {
    try {
      req.user = jwt.verify(token, process.env.JWT_SECRET);
      return next();
    } catch (e) {
      // Continue with default fallback
    }
  }
  req.user = { id: null, name: 'Dr. RKAM Deshan', role: 'doctor' };
  next();
};

// 1. Doctor Consultation Management CRUD
router.get('/queue', doctorAuth, getDailyQueue);
router.patch('/queue/:id/status', doctorAuth, updatePatientStatus);
router.post('/queue/:id/notes', doctorAuth, saveConsultationNotes);
router.delete('/queue/:id/skip', doctorAuth, skipPatient);
router.patch('/queue/:id/recall', doctorAuth, recallPatient);

// 2. Doctor Reports & Completed Summary
router.get('/reports/summary', doctorAuth, getDoctorSummary);

// 3. Patient Notification & Alert Dispatch CRUD
router.post('/alerts', doctorAuth, createDispatchAlert);
router.get('/alerts', doctorAuth, getDispatchAlerts);
router.delete('/alerts/:id', doctorAuth, deleteDispatchAlert);

module.exports = router;
