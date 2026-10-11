const Appointment = require('../models/Appointment');
const DispatchAlert = require('../models/DispatchAlert');

// 1. DOCTOR CONSULTATION MANAGEMENT CRUD

// READ: View today's assigned patient consultation queue list
exports.getDailyQueue = async (req, res) => {
  try {
    const { status, search } = req.query;
    const query = {};

    if (status && status !== 'all') {
      query.status = status;
    } else {
      // By default exclude cancelled
      query.status = { $ne: 'cancelled' };
    }

    let appointments = await Appointment.find(query)
      .populate('patientId', 'name phone nic email')
      .sort({ createdAt: 1 });

    // Ensure token number and patientName are populated if missing
    appointments = appointments.map((apt, index) => {
      const obj = apt.toObject();
      if (!obj.tokenNumber) {
        obj.tokenNumber = `A-${101 + index}`;
      }
      if (!obj.patientName && obj.patientId && obj.patientId.name) {
        obj.patientName = obj.patientId.name;
      }
      return obj;
    });

    if (search) {
      const q = search.toLowerCase();
      appointments = appointments.filter(
        (a) =>
          (a.tokenNumber && a.tokenNumber.toLowerCase().includes(q)) ||
          (a.patientName && a.patientName.toLowerCase().includes(q)) ||
          (a.symptoms && a.symptoms.toLowerCase().includes(q))
      );
    }

    res.json(appointments);
  } catch (err) {
    console.error('getDailyQueue error:', err);
    res.status(500).json({ message: 'Failed to fetch queue list.' });
  }
};

// UPDATE: Update patient status to "In Consultation" or "Completed"
exports.updatePatientStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, roomNumber } = req.body;

    const allowed = ['waiting', 'in_consultation', 'completed', 'skipped'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ message: 'Invalid status value.' });
    }

    const updateData = { status };
    if (roomNumber) updateData.roomNumber = roomNumber;

    if (status === 'in_consultation') {
      updateData.consultationStartTime = new Date();
    } else if (status === 'completed') {
      updateData.consultationEndTime = new Date();
    }

    const appointment = await Appointment.findByIdAndUpdate(id, updateData, { new: true })
      .populate('patientId', 'name phone nic');

    if (!appointment) {
      return res.status(404).json({ message: 'Appointment not found.' });
    }

    // Auto-dispatch alert when calling patient into consultation room
    if (status === 'in_consultation') {
      const token = appointment.tokenNumber || 'A-101';
      const room = appointment.roomNumber || 'Consultation Room 2';
      const patientName = appointment.patientName || (appointment.patientId ? appointment.patientId.name : 'Patient');

      await DispatchAlert.create({
        doctorId: req.user ? req.user.id : null,
        doctorName: req.user ? req.user.name : 'Dr. RKAM Deshan',
        tokenNumber: token,
        patientName,
        roomNumber: room,
        message: `${token} - ${patientName} please enter ${room}`,
        alertType: 'queue_call',
        priority: 'normal',
      });
    }

    res.json(appointment);
  } catch (err) {
    console.error('updatePatientStatus error:', err);
    res.status(500).json({ message: 'Failed to update patient status.' });
  }
};

// CREATE: Add clinical notes, diagnosis remarks, or prescription details per appointment
exports.saveConsultationNotes = async (req, res) => {
  try {
    const { id } = req.params;
    const { clinicalNotes, diagnosis, prescription, markCompleted } = req.body;

    const updateData = {
      clinicalNotes: clinicalNotes || '',
      diagnosis: diagnosis || '',
      prescription: prescription || '',
    };

    if (markCompleted) {
      updateData.status = 'completed';
      updateData.consultationEndTime = new Date();
    }

    const appointment = await Appointment.findByIdAndUpdate(id, updateData, { new: true })
      .populate('patientId', 'name phone nic');

    if (!appointment) {
      return res.status(404).json({ message: 'Appointment not found.' });
    }

    res.json(appointment);
  } catch (err) {
    console.error('saveConsultationNotes error:', err);
    res.status(500).json({ message: 'Failed to save consultation notes.' });
  }
};

// DELETE: Dismiss/skip absent or non-responsive patients from immediate active queue
exports.skipPatient = async (req, res) => {
  try {
    const { id } = req.params;
    const appointment = await Appointment.findByIdAndUpdate(
      id,
      { status: 'skipped' },
      { new: true }
    ).populate('patientId', 'name phone nic');

    if (!appointment) {
      return res.status(404).json({ message: 'Appointment not found.' });
    }

    res.json({ message: 'Patient skipped from active queue.', appointment });
  } catch (err) {
    console.error('skipPatient error:', err);
    res.status(500).json({ message: 'Failed to skip patient.' });
  }
};

// Recall patient back to waiting list
exports.recallPatient = async (req, res) => {
  try {
    const { id } = req.params;
    const appointment = await Appointment.findByIdAndUpdate(
      id,
      { status: 'waiting' },
      { new: true }
    ).populate('patientId', 'name phone nic');

    if (!appointment) {
      return res.status(404).json({ message: 'Appointment not found.' });
    }

    res.json({ message: 'Patient recalled to waiting queue.', appointment });
  } catch (err) {
    console.error('recallPatient error:', err);
    res.status(500).json({ message: 'Failed to recall patient.' });
  }
};

// 2. DOCTOR REPORTS & COMPLETED SUMMARY

exports.getDoctorSummary = async (req, res) => {
  try {
    const all = await Appointment.find({ status: { $ne: 'cancelled' } })
      .populate('patientId', 'name phone nic')
      .sort({ updatedAt: -1 });

    const waiting = all.filter((a) => a.status === 'waiting' || a.status === 'upcoming');
    const inConsultation = all.filter((a) => a.status === 'in_consultation');
    const completed = all.filter((a) => a.status === 'completed');
    const skipped = all.filter((a) => a.status === 'skipped');

    res.json({
      totalPatients: all.length,
      waitingCount: waiting.length,
      inConsultationCount: inConsultation.length,
      completedCount: completed.length,
      skippedCount: skipped.length,
      completedList: completed,
      currentActive: inConsultation[0] || null,
    });
  } catch (err) {
    console.error('getDoctorSummary error:', err);
    res.status(500).json({ message: 'Failed to generate report summary.' });
  }
};

// 3. PATIENT NOTIFICATION & ALERT DISPATCH CRUD

// CREATE: Trigger real-time queue call notifications ("Token A-104 enter Consultation Room 2")
exports.createDispatchAlert = async (req, res) => {
  try {
    const { tokenNumber, patientName, roomNumber, message, alertType, priority } = req.body;

    if (!tokenNumber) {
      return res.status(400).json({ message: 'Token number is required.' });
    }

    const room = roomNumber || 'Consultation Room 2';
    const alertMsg = message || `${tokenNumber} please enter ${room}`;

    const alert = await DispatchAlert.create({
      doctorId: req.user ? req.user.id : null,
      doctorName: req.user ? req.user.name : 'Dr. RKAM Deshan',
      tokenNumber,
      patientName: patientName || 'Patient',
      roomNumber: room,
      message: alertMsg,
      alertType: alertType || 'queue_call',
      priority: priority || 'normal',
    });

    res.status(201).json(alert);
  } catch (err) {
    console.error('createDispatchAlert error:', err);
    res.status(500).json({ message: 'Failed to create dispatch alert.' });
  }
};

// READ: View notification dispatch logs
exports.getDispatchAlerts = async (req, res) => {
  try {
    const alerts = await DispatchAlert.find().sort({ createdAt: -1 }).limit(50);
    res.json(alerts);
  } catch (err) {
    console.error('getDispatchAlerts error:', err);
    res.status(500).json({ message: 'Failed to fetch dispatch alerts.' });
  }
};

// DELETE: Clear or dismiss sent notification items
exports.deleteDispatchAlert = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await DispatchAlert.findByIdAndDelete(id);
    if (!deleted) {
      return res.status(404).json({ message: 'Alert not found.' });
    }
    res.json({ message: 'Notification alert dismissed successfully.', id });
  } catch (err) {
    console.error('deleteDispatchAlert error:', err);
    res.status(500).json({ message: 'Failed to dismiss notification alert.' });
  }
};
