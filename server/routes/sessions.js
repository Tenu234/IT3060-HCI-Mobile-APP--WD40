// Admin OPD Management: full CRUD on OPD sessions
const router = require('express').Router();
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { todayStr, isValidDate, isValidTime, sessionStatus } = require('../utils');

router.use(requireAuth, requireRole('admin'));

const SELECT = `
  SELECT s.*, c.name AS clinic_name, c.hospital, c.district,
    (SELECT COUNT(*) FROM appointments a WHERE a.session_id = s.id AND a.status <> 'cancelled') AS booked
  FROM sessions s JOIN clinics c ON c.id = s.clinic_id`;

const shape = (s) => ({ ...s, display_status: sessionStatus(s) });

function validate(b, partial = false) {
  const e = {};
  if (!partial || b.clinic_id !== undefined) {
    if (!b.clinic_id || !db.prepare('SELECT 1 FROM clinics WHERE id=?').get(b.clinic_id)) e.clinic_id = 'Select a valid clinic.';
  }
  if (!b.room || !String(b.room).trim()) e.room = 'Room is required.';
  if (!b.doctor || !String(b.doctor).trim()) e.doctor = 'Assigned doctor is required.';
  if (!isValidDate(b.date || '')) e.date = 'Use date format YYYY-MM-DD.';
  if (!isValidTime(b.start_time || '')) e.start_time = 'Use time format HH:MM (24h).';
  if (!isValidTime(b.end_time || '')) e.end_time = 'Use time format HH:MM (24h).';
  if (!e.start_time && !e.end_time && b.start_time >= b.end_time) e.end_time = 'End time must be after start time.';
  const max = Number(b.max_appointments);
  if (!Number.isInteger(max) || max < 1 || max > 500) e.max_appointments = 'Enter a number between 1 and 500.';
  return e;
}

function roomConflict(b, ignoreId = 0) {
  return db.prepare(`SELECT 1 FROM sessions WHERE id <> ? AND status='active' AND date=? AND LOWER(room)=LOWER(?)
    AND start_time < ? AND end_time > ?`).get(ignoreId, b.date, b.room, b.end_time, b.start_time);
}

// READ - list with filters + summary cards
router.get('/', (req, res) => {
  const { q = '', date = '', status = '' } = req.query;
  let rows = db.prepare(`${SELECT} ORDER BY s.date, s.start_time`).all().map(shape);
  if (date) rows = rows.filter((r) => r.date === date);
  if (status && status !== 'All') rows = rows.filter((r) => r.display_status.toLowerCase() === String(status).toLowerCase());
  const needle = String(q).trim().toLowerCase();
  if (needle) rows = rows.filter((r) => [r.clinic_name, r.room, r.doctor, r.hospital].some((v) => (v || '').toLowerCase().includes(needle)));
  const active = rows.filter((r) => r.display_status === 'Active' || r.display_status === 'Full');
  res.json({
    summary: {
      active_sessions: rows.filter((r) => r.display_status === 'Active').length,
      booked_appointments: rows.filter((r) => r.status === 'active').reduce((n, r) => n + r.booked, 0),
      doctors_on_duty: new Set(active.map((r) => r.doctor)).size,
    },
    sessions: rows,
  });
});

router.get('/:id', (req, res) => {
  const s = db.prepare(`${SELECT} WHERE s.id=?`).get(req.params.id);
  if (!s) return res.status(404).json({ error: 'Session not found.' });
  res.json({ session: shape(s) });
});

// CREATE
router.post('/', (req, res) => {
  const b = req.body || {};
  const e = validate(b);
  if (Object.keys(e).length) return res.status(400).json({ error: 'Please fix the highlighted fields.', fields: e });
  if (b.date < todayStr()) return res.status(400).json({ error: 'Cannot create a session in the past.', fields: { date: 'Choose today or a future date.' } });
  if (roomConflict(b)) return res.status(409).json({ error: 'That room already has a session at this time.', fields: { room: 'Room is already booked for this time.' } });
  const info = db.prepare(`INSERT INTO sessions (clinic_id, room, doctor, date, start_time, end_time, max_appointments, status)
    VALUES (?,?,?,?,?,?,?, 'active')`).run(b.clinic_id, b.room.trim(), b.doctor.trim(), b.date, b.start_time, b.end_time, Number(b.max_appointments));
  res.status(201).json({ session: shape(db.prepare(`${SELECT} WHERE s.id=?`).get(info.lastInsertRowid)) });
});

// UPDATE - requires confirm:true when bookings already exist and schedule changes
router.put('/:id', (req, res) => {
  const cur = db.prepare(`${SELECT} WHERE s.id=?`).get(req.params.id);
  if (!cur) return res.status(404).json({ error: 'Session not found.' });
  const b = { ...cur, ...req.body };
  const e = validate(b, true);
  if (Object.keys(e).length) return res.status(400).json({ error: 'Please fix the highlighted fields.', fields: e });
  const max = Number(b.max_appointments);
  if (max < cur.booked)
    return res.status(400).json({ error: `Capacity cannot be lower than the ${cur.booked} existing bookings.`, fields: { max_appointments: `Minimum ${cur.booked} (already booked).` } });
  if (roomConflict(b, cur.id)) return res.status(409).json({ error: 'That room already has a session at this time.', fields: { room: 'Room is already booked for this time.' } });

  const affects = ['room', 'doctor', 'date', 'start_time', 'end_time'].some((k) => String(b[k]) !== String(cur[k]));
  if (cur.booked > 0 && affects && req.body.confirm !== true)
    return res.status(409).json({ needs_confirmation: true, error: `This change affects ${cur.booked} existing booking(s). Confirm to save.` });

  db.prepare(`UPDATE sessions SET clinic_id=?, room=?, doctor=?, date=?, start_time=?, end_time=?, max_appointments=? WHERE id=?`)
    .run(b.clinic_id, b.room.trim(), b.doctor.trim(), b.date, b.start_time, b.end_time, max, cur.id);
  res.json({ session: shape(db.prepare(`${SELECT} WHERE s.id=?`).get(cur.id)) });
});

// UPDATE - close / reopen
router.patch('/:id/close', (req, res) => {
  const cur = db.prepare(`${SELECT} WHERE s.id=?`).get(req.params.id);
  if (!cur) return res.status(404).json({ error: 'Session not found.' });
  if (cur.booked > 0 && req.body?.confirm !== true)
    return res.status(409).json({ needs_confirmation: true, error: `Closing will cancel ${cur.booked} booking(s). Confirm to continue.` });
  db.transaction(() => {
    db.prepare(`UPDATE sessions SET status='closed' WHERE id=?`).run(cur.id);
    db.prepare(`UPDATE appointments SET status='cancelled' WHERE session_id=? AND status='booked'`).run(cur.id);
  })();
  res.json({ session: shape(db.prepare(`${SELECT} WHERE s.id=?`).get(cur.id)) });
});
router.patch('/:id/reopen', (req, res) => {
  const cur = db.prepare('SELECT 1 FROM sessions WHERE id=?').get(req.params.id);
  if (!cur) return res.status(404).json({ error: 'Session not found.' });
  db.prepare(`UPDATE sessions SET status='active' WHERE id=?`).run(req.params.id);
  res.json({ session: shape(db.prepare(`${SELECT} WHERE s.id=?`).get(req.params.id)) });
});

// DELETE - only when nothing is booked
router.delete('/:id', (req, res) => {
  const cur = db.prepare(`${SELECT} WHERE s.id=?`).get(req.params.id);
  if (!cur) return res.status(404).json({ error: 'Session not found.' });
  if (cur.booked > 0) return res.status(409).json({ error: `Cannot delete: ${cur.booked} booking(s) exist. Close the session instead.` });
  db.prepare('DELETE FROM sessions WHERE id=?').run(cur.id);
  res.json({ ok: true });
});

module.exports = router;
