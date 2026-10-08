// Minimal booking integration (owned by Member 2) so OPD Search -> Slots -> Booking works end to end.
const router = require('express').Router();
const db = require('../db');
const { requireAuth } = require('../middleware/auth');
const { todayStr } = require('../utils');

const VISIT = `
  SELECT a.id, a.token, a.status, a.created_at, s.date, s.start_time, s.end_time, s.room,
         s.doctor, c.name AS clinic_name, c.hospital, c.district
  FROM appointments a JOIN sessions s ON s.id = a.session_id JOIN clinics c ON c.id = s.clinic_id`;

// CREATE
router.post('/', requireAuth, (req, res) => {
  const { session_id, patient_id } = req.body || {};
  let userId = req.user.id;
  if (req.user.role !== 'patient') {
    if (!patient_id) return res.status(400).json({ error: 'Select a patient to book for.' });
    if (!db.prepare(`SELECT 1 FROM users WHERE id=? AND role='patient'`).get(patient_id)) return res.status(404).json({ error: 'Patient not found.' });
    userId = patient_id;
  }
  const s = db.prepare(`SELECT s.*, c.code,
      (SELECT COUNT(*) FROM appointments a WHERE a.session_id=s.id AND a.status<>'cancelled') AS booked
      FROM sessions s JOIN clinics c ON c.id=s.clinic_id WHERE s.id=?`).get(session_id);
  if (!s) return res.status(404).json({ error: 'Session not found.' });
  if (s.status !== 'active') return res.status(409).json({ error: 'This session is closed.' });
  if (s.date < todayStr()) return res.status(409).json({ error: 'This session is in the past.' });
  if (s.booked >= s.max_appointments) return res.status(409).json({ error: 'This slot is full. Please choose another time.' });
  if (db.prepare(`SELECT 1 FROM appointments WHERE user_id=? AND session_id=? AND status<>'cancelled'`).get(userId, s.id))
    return res.status(409).json({ error: 'Already booked for this slot.' });

  const info = db.prepare(`INSERT INTO appointments (token, user_id, session_id) VALUES ('', ?, ?)`).run(userId, s.id);
  const token = `${s.code}-${String(info.lastInsertRowid).padStart(3, '0')}`;
  db.prepare('UPDATE appointments SET token=? WHERE id=?').run(token, info.lastInsertRowid);
  res.status(201).json({ appointment: db.prepare(`${VISIT} WHERE a.id=?`).get(info.lastInsertRowid), queue_number: s.booked + 1 });
});

// READ - own appointments
router.get('/mine', requireAuth, (req, res) => {
  res.json({ appointments: db.prepare(`${VISIT} WHERE a.user_id=? ORDER BY s.date DESC, s.start_time DESC`).all(req.user.id) });
});

// UPDATE - cancel
router.put('/:id/cancel', requireAuth, (req, res) => {
  const a = db.prepare('SELECT * FROM appointments WHERE id=?').get(req.params.id);
  if (!a) return res.status(404).json({ error: 'Appointment not found.' });
  if (req.user.role === 'patient' && a.user_id !== req.user.id) return res.status(403).json({ error: 'Not your appointment.' });
  if (a.status !== 'booked') return res.status(409).json({ error: 'Only booked appointments can be cancelled.' });
  db.prepare(`UPDATE appointments SET status='cancelled' WHERE id=?`).run(a.id);
  res.json({ appointment: db.prepare(`${VISIT} WHERE a.id=?`).get(a.id) });
});

module.exports = router;
