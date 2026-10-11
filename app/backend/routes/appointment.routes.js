const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const {
  getMyAppointments,
  bookAppointment,
  cancelAppointment,
  rescheduleAppointment,
} = require('../controllers/appointment.controller');

router.get('/',              auth, getMyAppointments);
router.post('/',             auth, bookAppointment);
router.patch('/:id/cancel',      auth, cancelAppointment);
router.patch('/:id/reschedule',  auth, rescheduleAppointment);

module.exports = router;
