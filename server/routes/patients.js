// Authorized patient search + profile & visit history (staff/admin only)
const router = require('express').Router();
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { maskNic } = require('../utils');

router.use(requireAuth, requireRole('staff', 'admin'));

const card = (u) => ({
  id: u.id, reg_id: u.reg_id, full_name: u.full_name, nic_masked: maskNic(u.nic), age: u.age,
  gender: u.gender, mobile: u.mobile, blood_group: u.blood_group, clinical_notes: u.clinical_notes,
});

const visits = (userId) => db.prepare(`
  SELECT a.id, a.token, a.status, a.created_at, s.date, s.start_time, s.end_time, s.room, s.doctor,
         c.name AS clinic_name, c.hospital
  FROM appointments a JOIN sessions s ON s.id=a.session_id JOIN clinics c ON c.id=s.clinic_id
  WHERE a.user_id=? ORDER BY s.date DESC, s.start_time DESC`).all(userId);

// READ - search by NIC or registration ID
router.get('/search', (req, res) => {
  const q = String(req.query.q || '').trim().toUpperCase();
  if (!q) return res.status(400).json({ error: 'Enter a NIC or registration ID.' });
  const u = db.prepare(`SELECT * FROM users WHERE role='patient' AND (UPPER(nic)=? OR UPPER(reg_id)=?)`).get(q, q);
  if (!u) return res.status(404).json({ error: 'No patient found for that NIC or registration ID.' });
  res.json({ patient: card(u), visits: visits(u.id) });
});

// READ - full profile + history
router.get('/:id', (req, res) => {
  const u = db.prepare(`SELECT * FROM users WHERE id=? AND role='patient'`).get(req.params.id);
  if (!u) return res.status(404).json({ error: 'Patient not found.' });
  res.json({ patient: card(u), visits: visits(u.id) });
});

// UPDATE - clinical details (staff-only data)
router.put('/:id', (req, res) => {
  const u = db.prepare(`SELECT * FROM users WHERE id=? AND role='patient'`).get(req.params.id);
  if (!u) return res.status(404).json({ error: 'Patient not found.' });
  const groups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'];
  const bg = req.body.blood_group ?? u.blood_group;
  if (!groups.includes(bg)) return res.status(400).json({ error: 'Invalid blood group.' });
  const notes = String(req.body.clinical_notes ?? u.clinical_notes).slice(0, 1000);
  db.prepare('UPDATE users SET blood_group=?, clinical_notes=? WHERE id=?').run(bg, notes, u.id);
  res.json({ patient: card(db.prepare('SELECT * FROM users WHERE id=?').get(u.id)) });
});

module.exports = router;
