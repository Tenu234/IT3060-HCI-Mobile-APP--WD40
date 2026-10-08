// OPD Search: browse/filter clinics, view slots, save favourite clinics
const router = require('express').Router();
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { todayStr, addDays, sessionStatus } = require('../utils');

const BOOKED = `(SELECT COUNT(*) FROM appointments a WHERE a.session_id = s.id AND a.status <> 'cancelled')`;

// READ - search clinics (q, district, clinic, openToday, saved)
router.get('/', requireAuth, (req, res) => {
  const { q = '', district = '', clinic = '', openToday = '', saved = '' } = req.query;
  const today = todayStr();
  let rows = db.prepare(`
    SELECT c.*,
      EXISTS(SELECT 1 FROM favorites f WHERE f.user_id = ? AND f.clinic_id = c.id) AS saved,
      (SELECT COALESCE(SUM(${BOOKED}),0) FROM sessions s WHERE s.clinic_id = c.id AND s.date = ? AND s.status='active') AS waiting,
      (SELECT COUNT(*) FROM sessions s WHERE s.clinic_id = c.id AND s.date = ? AND s.status='active') AS sessions_today
    FROM clinics c ORDER BY c.hospital`).all(req.user.id, today, today);

  const needle = String(q).trim().toLowerCase();
  const districts = String(district).split(',').filter(Boolean).map((x) => x.toLowerCase());
  const clinics = String(clinic).split(',').filter(Boolean).map((x) => x.toLowerCase());
  rows = rows.filter((c) => {
    if (needle && ![c.hospital, c.name, c.doctor, c.district].some((v) => (v || '').toLowerCase().includes(needle))) return false;
    if (districts.length && !districts.includes(c.district.toLowerCase())) return false;
    if (clinics.length && !clinics.includes(c.name.toLowerCase())) return false;
    if (openToday === 'true' && c.sessions_today === 0) return false;
    if (saved === 'true' && !c.saved) return false;
    return true;
  }).map((c) => ({ ...c, saved: !!c.saved, open_today: c.sessions_today > 0 }));
  res.json({ count: rows.length, clinics: rows });
});

// READ - filter options
router.get('/filters', requireAuth, (req, res) => {
  res.json({
    districts: db.prepare('SELECT DISTINCT district d FROM clinics ORDER BY d').all().map((r) => r.d),
    clinics: db.prepare('SELECT DISTINCT name n FROM clinics ORDER BY n').all().map((r) => r.n),
  });
});

// READ - one clinic with next 7 days of slots
router.get('/:id', requireAuth, (req, res) => {
  const clinic = db.prepare('SELECT * FROM clinics WHERE id=?').get(req.params.id);
  if (!clinic) return res.status(404).json({ error: 'Clinic not found.' });
  const from = todayStr();
  const to = addDays(from, 6);
  const sessions = db.prepare(`
    SELECT s.*, ${BOOKED} AS booked FROM sessions s
    WHERE s.clinic_id = ? AND s.date BETWEEN ? AND ? AND s.status = 'active'
    ORDER BY s.date, s.start_time`).all(clinic.id, from, to);
  const slots = sessions.map((s) => ({
    id: s.id, date: s.date, start_time: s.start_time, end_time: s.end_time,
    room: s.room, doctor: s.doctor, capacity: s.max_appointments, booked: s.booked,
    left: Math.max(s.max_appointments - s.booked, 0), full: s.booked >= s.max_appointments,
    status: sessionStatus(s),
  }));
  res.json({ clinic, slots });
});

// CREATE / DELETE - save a clinic as favourite
router.post('/:id/favorite', requireAuth, (req, res) => {
  if (!db.prepare('SELECT 1 FROM clinics WHERE id=?').get(req.params.id)) return res.status(404).json({ error: 'Clinic not found.' });
  db.prepare('INSERT OR IGNORE INTO favorites (user_id, clinic_id) VALUES (?,?)').run(req.user.id, req.params.id);
  res.status(201).json({ saved: true });
});
router.delete('/:id/favorite', requireAuth, (req, res) => {
  db.prepare('DELETE FROM favorites WHERE user_id=? AND clinic_id=?').run(req.user.id, req.params.id);
  res.json({ saved: false });
});

// Admin: manage clinics (CRUD)
router.post('/', requireAuth, requireRole('admin'), (req, res) => {
  const { hospital, name, code, district, room, doctor, description, days, open_time, close_time } = req.body || {};
  if (!hospital || !name || !district) return res.status(400).json({ error: 'Hospital, clinic name and district are required.' });
  const info = db.prepare(`INSERT INTO clinics (hospital,name,code,district,room,doctor,description,days,open_time,close_time)
    VALUES (?,?,?,?,?,?,?,?,?,?)`).run(hospital, name, (code || name[0]).toUpperCase(), district, room || '', doctor || '', description || '', days || 'Mon-Fri', open_time || '08:00', close_time || '16:00');
  res.status(201).json({ clinic: db.prepare('SELECT * FROM clinics WHERE id=?').get(info.lastInsertRowid) });
});
router.put('/:id', requireAuth, requireRole('admin'), (req, res) => {
  const c = db.prepare('SELECT * FROM clinics WHERE id=?').get(req.params.id);
  if (!c) return res.status(404).json({ error: 'Clinic not found.' });
  const m = { ...c, ...req.body, id: c.id };
  db.prepare(`UPDATE clinics SET hospital=?,name=?,code=?,district=?,room=?,doctor=?,description=?,days=?,open_time=?,close_time=? WHERE id=?`)
    .run(m.hospital, m.name, m.code, m.district, m.room, m.doctor, m.description, m.days, m.open_time, m.close_time, c.id);
  res.json({ clinic: db.prepare('SELECT * FROM clinics WHERE id=?').get(c.id) });
});
router.delete('/:id', requireAuth, requireRole('admin'), (req, res) => {
  const n = db.prepare(`SELECT COUNT(*) c FROM appointments a JOIN sessions s ON s.id=a.session_id
    WHERE s.clinic_id=? AND a.status='booked'`).get(req.params.id).c;
  if (n > 0) return res.status(409).json({ error: `Cannot delete: ${n} active booking(s) exist.` });
  db.prepare('DELETE FROM clinics WHERE id=?').run(req.params.id);
  res.json({ ok: true });
});

module.exports = router;
