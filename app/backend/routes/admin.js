// OPD Clinic Admin dashboard: summary, booking list, clinic management, doctor management.
const router = require('express').Router();
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { todayStr, isValidTime, normalizeMobile, isValidMobile, isValidNic, maskNic } = require('../utils');

router.use(requireAuth, requireRole('admin'));

const DAYS = ['Mon-Fri', 'Mon-Sat', 'Mon-Sun'];

/* ------------------------------ SUMMARY ------------------------------ */
router.get('/summary', (req, res) => {
  const t = todayStr();
  const one = (sql, ...p) => db.prepare(sql).get(...p).c;
  res.json({
    bookings_today: one(`SELECT COUNT(*) c FROM appointments a JOIN sessions s ON s.id=a.session_id WHERE s.date=? AND a.status<>'cancelled'`, t),
    upcoming_bookings: one(`SELECT COUNT(*) c FROM appointments a JOIN sessions s ON s.id=a.session_id WHERE s.date>=? AND a.status='booked'`, t),
    clinics_active: one(`SELECT COUNT(*) c FROM clinics WHERE status='active'`),
    clinics_on_hold: one(`SELECT COUNT(*) c FROM clinics WHERE status='on_hold'`),
    doctors_total: one(`SELECT COUNT(*) c FROM doctors`),
    doctors_on_leave: one(`SELECT COUNT(*) c FROM doctors WHERE status='on_leave'`),
  });
});

/* ------------------------------ BOOKINGS ----------------------------- */
const BOOKING = `
  SELECT a.id, a.token, a.status, a.created_at,
         s.date, s.start_time, s.end_time, s.room, s.doctor,
         c.id AS clinic_id, c.name AS clinic_name, c.hospital,
         u.id AS patient_id, u.full_name AS patient_name, u.reg_id, u.mobile
  FROM appointments a
  JOIN sessions s ON s.id = a.session_id
  JOIN clinics  c ON c.id = s.clinic_id
  JOIN users    u ON u.id = a.user_id`;

// READ - booking list with filters
router.get('/bookings', (req, res) => {
  const { q = '', date = '', status = '', clinic_id = '' } = req.query;
  const where = [];
  const params = [];
  if (date) { where.push('s.date = ?'); params.push(date); }
  if (status && status !== 'All') { where.push('a.status = ?'); params.push(String(status).toLowerCase()); }
  if (clinic_id) { where.push('c.id = ?'); params.push(clinic_id); }
  if (String(q).trim()) {
    where.push(`(u.full_name LIKE ? OR u.reg_id LIKE ? OR a.token LIKE ? OR c.name LIKE ? OR s.doctor LIKE ?)`);
    const like = `%${String(q).trim()}%`;
    params.push(like, like, like, like, like);
  }
  const sql = `${BOOKING} ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY s.date DESC, s.start_time DESC, a.id DESC LIMIT 500`;
  const bookings = db.prepare(sql).all(...params);
  res.json({ count: bookings.length, bookings });
});

// CREATE - admin books a token for a patient (walk-in / phone booking)
router.post('/bookings', (req, res) => {
  const { patient_id, session_id } = req.body || {};
  if (!db.prepare(`SELECT 1 FROM users WHERE id=? AND role='patient'`).get(patient_id))
    return res.status(404).json({ error: 'Select a valid patient.', fields: { patient_id: 'Select a patient.' } });
  const s = db.prepare(`SELECT s.*, c.code, c.status AS clinic_status,
      (SELECT COUNT(*) FROM appointments a WHERE a.session_id=s.id AND a.status<>'cancelled') AS booked
      FROM sessions s JOIN clinics c ON c.id=s.clinic_id WHERE s.id=?`).get(session_id);
  if (!s) return res.status(404).json({ error: 'Select a valid time slot.', fields: { session_id: 'Select a slot.' } });
  if (s.clinic_status === 'on_hold') return res.status(409).json({ error: 'This clinic is on hold. Resume it before booking.' });
  if (s.status !== 'active') return res.status(409).json({ error: 'This session is closed.' });
  if (s.date < todayStr()) return res.status(409).json({ error: 'This session is in the past.' });
  if (s.booked >= s.max_appointments) return res.status(409).json({ error: 'This slot is full. Choose another time.' });
  if (db.prepare(`SELECT 1 FROM appointments WHERE user_id=? AND session_id=? AND status<>'cancelled'`).get(patient_id, s.id))
    return res.status(409).json({ error: 'This patient already has a booking in this slot.' });
  const info = db.prepare(`INSERT INTO appointments (token, user_id, session_id) VALUES ('', ?, ?)`).run(patient_id, s.id);
  const token = `${s.code}-${String(info.lastInsertRowid).padStart(3, '0')}`;
  db.prepare('UPDATE appointments SET token=? WHERE id=?').run(token, info.lastInsertRowid);
  res.status(201).json({ booking: db.prepare(`${BOOKING} WHERE a.id=?`).get(info.lastInsertRowid), queue_number: s.booked + 1 });
});

// UPDATE - mark booked / completed / cancelled
router.put('/bookings/:id/status', (req, res) => {
  const status = String(req.body?.status || '').toLowerCase();
  if (!['booked', 'completed', 'cancelled'].includes(status))
    return res.status(400).json({ error: 'Status must be booked, completed or cancelled.' });
  if (!db.prepare('SELECT 1 FROM appointments WHERE id=?').get(req.params.id))
    return res.status(404).json({ error: 'Booking not found.' });
  db.prepare('UPDATE appointments SET status=? WHERE id=?').run(status, req.params.id);
  res.json({ booking: db.prepare(`${BOOKING} WHERE a.id=?`).get(req.params.id) });
});

// DELETE - remove a booking record
router.delete('/bookings/:id', (req, res) => {
  const info = db.prepare('DELETE FROM appointments WHERE id=?').run(req.params.id);
  if (!info.changes) return res.status(404).json({ error: 'Booking not found.' });
  res.json({ ok: true });
});

/* ------------------------------- CLINICS ----------------------------- */
const CLINIC = `
  SELECT c.*, d.name AS doctor_name,
    (SELECT COUNT(*) FROM appointments a JOIN sessions s ON s.id=a.session_id
       WHERE s.clinic_id=c.id AND s.date>=? AND a.status='booked') AS upcoming_bookings,
    (SELECT COUNT(*) FROM sessions s WHERE s.clinic_id=c.id AND s.date>=? AND s.status='active') AS upcoming_sessions
  FROM clinics c LEFT JOIN doctors d ON d.id = c.doctor_id`;
const clinicRow = (id) => db.prepare(`${CLINIC} WHERE c.id=?`).get(todayStr(), todayStr(), id);

function validateClinic(b) {
  const e = {};
  if (!b.hospital || String(b.hospital).trim().length < 3) e.hospital = 'Enter the hospital name.';
  if (!b.name || String(b.name).trim().length < 2) e.name = 'Enter the clinic name.';
  if (!b.district || !String(b.district).trim()) e.district = 'Select a district.';
  if (b.code && !/^[A-Za-z]{1,3}$/.test(String(b.code))) e.code = 'Token prefix must be 1-3 letters.';
  if (!isValidTime(b.open_time || '')) e.open_time = 'Select opening time.';
  if (!isValidTime(b.close_time || '')) e.close_time = 'Select closing time.';
  if (!e.open_time && !e.close_time && b.open_time >= b.close_time) e.close_time = 'Closing time must be after opening time.';
  if (!DAYS.includes(b.days)) e.days = 'Select operating days.';
  if (b.doctor_id && !db.prepare('SELECT 1 FROM doctors WHERE id=?').get(b.doctor_id)) e.doctor_id = 'Select a valid doctor.';
  return e;
}
const doctorName = (id) => (id ? db.prepare('SELECT name FROM doctors WHERE id=?').get(id)?.name || '' : '');

// READ - all clinics (admin sees on-hold ones too)
router.get('/clinics', (req, res) => {
  const { q = '', status = '' } = req.query;
  let rows = db.prepare(`${CLINIC} ORDER BY c.hospital, c.name`).all(todayStr(), todayStr());
  if (status && status !== 'All') rows = rows.filter((c) => c.status === String(status).toLowerCase().replace(' ', '_'));
  const n = String(q).trim().toLowerCase();
  if (n) rows = rows.filter((c) => [c.hospital, c.name, c.district, c.doctor_name].some((v) => (v || '').toLowerCase().includes(n)));
  res.json({ count: rows.length, clinics: rows });
});

router.get('/clinics/:id', (req, res) => {
  const c = clinicRow(req.params.id);
  if (!c) return res.status(404).json({ error: 'Clinic not found.' });
  res.json({ clinic: c });
});

// CREATE
router.post('/clinics', (req, res) => {
  const b = req.body || {};
  const e = validateClinic(b);
  if (Object.keys(e).length) return res.status(400).json({ error: 'Please fix the highlighted fields.', fields: e });
  if (db.prepare('SELECT 1 FROM clinics WHERE LOWER(hospital)=LOWER(?) AND LOWER(name)=LOWER(?)').get(b.hospital.trim(), b.name.trim()))
    return res.status(409).json({ error: 'This clinic already exists at that hospital.', fields: { name: 'Clinic already exists at this hospital.' } });
  const info = db.prepare(`INSERT INTO clinics (hospital,name,code,district,room,doctor,doctor_id,description,days,open_time,close_time,status)
    VALUES (?,?,?,?,?,?,?,?,?,?,?, 'active')`).run(
    b.hospital.trim(), b.name.trim(), String(b.code || b.name[0]).toUpperCase(), b.district.trim(), (b.room || '').trim(),
    doctorName(b.doctor_id), b.doctor_id || null, (b.description || '').trim(), b.days, b.open_time, b.close_time);
  res.status(201).json({ clinic: clinicRow(info.lastInsertRowid) });
});

// UPDATE
router.put('/clinics/:id', (req, res) => {
  const cur = db.prepare('SELECT * FROM clinics WHERE id=?').get(req.params.id);
  if (!cur) return res.status(404).json({ error: 'Clinic not found.' });
  const b = { ...cur, ...req.body };
  const e = validateClinic(b);
  if (Object.keys(e).length) return res.status(400).json({ error: 'Please fix the highlighted fields.', fields: e });
  if (db.prepare('SELECT 1 FROM clinics WHERE id<>? AND LOWER(hospital)=LOWER(?) AND LOWER(name)=LOWER(?)').get(cur.id, b.hospital.trim(), b.name.trim()))
    return res.status(409).json({ error: 'This clinic already exists at that hospital.', fields: { name: 'Clinic already exists at this hospital.' } });
  db.prepare(`UPDATE clinics SET hospital=?,name=?,code=?,district=?,room=?,doctor=?,doctor_id=?,description=?,days=?,open_time=?,close_time=? WHERE id=?`)
    .run(b.hospital.trim(), b.name.trim(), String(b.code || b.name[0]).toUpperCase(), b.district.trim(), (b.room || '').trim(),
      doctorName(b.doctor_id), b.doctor_id || null, (b.description || '').trim(), b.days, b.open_time, b.close_time, cur.id);
  res.json({ clinic: clinicRow(cur.id) });
});

// UPDATE - put on hold (bookings paused) / resume
router.patch('/clinics/:id/hold', (req, res) => {
  const cur = clinicRow(req.params.id);
  if (!cur) return res.status(404).json({ error: 'Clinic not found.' });
  db.prepare(`UPDATE clinics SET status='on_hold', hold_reason=? WHERE id=?`).run(String(req.body?.reason || '').trim().slice(0, 200), cur.id);
  res.json({ clinic: clinicRow(cur.id), affected_bookings: cur.upcoming_bookings });
});
router.patch('/clinics/:id/resume', (req, res) => {
  if (!db.prepare('SELECT 1 FROM clinics WHERE id=?').get(req.params.id)) return res.status(404).json({ error: 'Clinic not found.' });
  db.prepare(`UPDATE clinics SET status='active', hold_reason='' WHERE id=?`).run(req.params.id);
  res.json({ clinic: clinicRow(req.params.id) });
});

// DELETE - blocked while upcoming bookings exist
router.delete('/clinics/:id', (req, res) => {
  const c = clinicRow(req.params.id);
  if (!c) return res.status(404).json({ error: 'Clinic not found.' });
  if (c.upcoming_bookings > 0)
    return res.status(409).json({ error: `Cannot delete: ${c.upcoming_bookings} upcoming booking(s). Put the clinic on hold instead.` });
  db.prepare('DELETE FROM clinics WHERE id=?').run(c.id);
  res.json({ ok: true });
});

/* ------------------------------- DOCTORS ----------------------------- */
const DOCTOR = `
  SELECT d.*,
    (SELECT COUNT(*) FROM clinics c WHERE c.doctor_id=d.id) AS clinics_count,
    (SELECT GROUP_CONCAT(c.name, ', ') FROM clinics c WHERE c.doctor_id=d.id) AS clinic_names
  FROM doctors d`;

function validateDoctor(b, ignoreId = 0) {
  const e = {};
  const name = String(b.name || '').trim();
  if (name.length < 3) e.name = 'Enter the doctor\'s full name.';
  else if (db.prepare('SELECT 1 FROM doctors WHERE id<>? AND name=?').get(ignoreId, name)) e.name = 'A doctor with this name already exists.';
  if (!b.specialty || !String(b.specialty).trim()) e.specialty = 'Select a specialty.';
  if (b.phone && !/^\+?\d[\d\s-]{6,14}$/.test(String(b.phone))) e.phone = 'Enter a valid phone number.';
  if (b.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(b.email))) e.email = 'Enter a valid email address.';
  if (!['active', 'on_leave'].includes(b.status || 'active')) e.status = 'Invalid status.';
  return e;
}

// READ
router.get('/doctors', (req, res) => {
  const { q = '', status = '' } = req.query;
  let rows = db.prepare(`${DOCTOR} ORDER BY d.name`).all();
  if (status && status !== 'All') rows = rows.filter((d) => d.status === String(status).toLowerCase().replace(' ', '_'));
  const n = String(q).trim().toLowerCase();
  if (n) rows = rows.filter((d) => [d.name, d.specialty, d.phone, d.clinic_names].some((v) => (v || '').toLowerCase().includes(n)));
  res.json({ count: rows.length, doctors: rows });
});

// CREATE
router.post('/doctors', (req, res) => {
  const b = req.body || {};
  const e = validateDoctor(b);
  if (Object.keys(e).length) return res.status(400).json({ error: 'Please fix the highlighted fields.', fields: e });
  const info = db.prepare('INSERT INTO doctors (name, specialty, phone, email, status) VALUES (?,?,?,?,?)')
    .run(b.name.trim(), b.specialty.trim(), (b.phone || '').trim(), (b.email || '').trim(), b.status || 'active');
  res.status(201).json({ doctor: db.prepare(`${DOCTOR} WHERE d.id=?`).get(info.lastInsertRowid) });
});

// UPDATE (also keeps clinic display names in sync)
router.put('/doctors/:id', (req, res) => {
  const cur = db.prepare('SELECT * FROM doctors WHERE id=?').get(req.params.id);
  if (!cur) return res.status(404).json({ error: 'Doctor not found.' });
  const b = { ...cur, ...req.body };
  const e = validateDoctor(b, cur.id);
  if (Object.keys(e).length) return res.status(400).json({ error: 'Please fix the highlighted fields.', fields: e });
  db.transaction(() => {
    db.prepare('UPDATE doctors SET name=?, specialty=?, phone=?, email=?, status=? WHERE id=?')
      .run(b.name.trim(), b.specialty.trim(), (b.phone || '').trim(), (b.email || '').trim(), b.status, cur.id);
    db.prepare('UPDATE clinics SET doctor=? WHERE doctor_id=?').run(b.name.trim(), cur.id);
  })();
  res.json({ doctor: db.prepare(`${DOCTOR} WHERE d.id=?`).get(cur.id) });
});

// DELETE - blocked while assigned to a clinic
router.delete('/doctors/:id', (req, res) => {
  const d = db.prepare(`${DOCTOR} WHERE d.id=?`).get(req.params.id);
  if (!d) return res.status(404).json({ error: 'Doctor not found.' });
  if (d.clinics_count > 0)
    return res.status(409).json({ error: `Cannot delete: assigned to ${d.clinics_count} clinic(s) (${d.clinic_names}). Reassign them first.` });
  db.prepare('DELETE FROM doctors WHERE id=?').run(d.id);
  res.json({ ok: true });
});

/* ------------------------------ PATIENTS ----------------------------- */
const GENDERS = ['Male', 'Female', 'Other'];
const BLOOD = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'];
const PATIENT = `
  SELECT u.id, u.reg_id, u.full_name, u.nic, u.age, u.gender, u.mobile, u.blood_group, u.clinical_notes,
    (SELECT COUNT(*) FROM appointments a WHERE a.user_id=u.id) AS total_visits,
    (SELECT COUNT(*) FROM appointments a JOIN sessions s ON s.id=a.session_id
       WHERE a.user_id=u.id AND a.status='booked' AND s.date>=?) AS upcoming_bookings
  FROM users u WHERE u.role='patient'`;
const patientOut = (p) => ({ ...p, nic_masked: maskNic(p.nic), nic: undefined });
const patientRow = (id) => {
  const p = db.prepare(`${PATIENT} AND u.id=?`).get(todayStr(), id);
  return p ? patientOut(p) : null;
};

function validatePatient(b, creating, ignoreId = 0) {
  const e = {};
  if (!b.full_name || String(b.full_name).trim().length < 3) e.full_name = 'Enter the patient\'s full name.';
  if (creating) {
    const nic = String(b.nic || '').trim().toUpperCase();
    if (!isValidNic(nic)) e.nic = 'NIC must be 12 digits, or 9 digits followed by V/X.';
    else if (db.prepare('SELECT 1 FROM users WHERE nic=?').get(nic)) e.nic = 'This NIC is already registered.';
  }
  const age = Number(b.age);
  if (!Number.isInteger(age) || age < 0 || age > 120) e.age = 'Enter a valid age (0-120).';
  if (!GENDERS.includes(b.gender)) e.gender = 'Select a gender.';
  const mob = normalizeMobile(b.mobile);
  if (!isValidMobile(mob)) e.mobile = 'Enter a valid mobile, e.g. +94 77 123 4567.';
  else if (db.prepare('SELECT 1 FROM users WHERE mobile=? AND id<>?').get(mob, ignoreId)) e.mobile = 'Mobile number already in use.';
  if (b.blood_group && !BLOOD.includes(b.blood_group)) e.blood_group = 'Invalid blood group.';
  return e;
}

// READ - patient list
router.get('/patients', (req, res) => {
  const n = String(req.query.q || '').trim().toLowerCase();
  let rows = db.prepare(`${PATIENT} ORDER BY u.full_name`).all(todayStr());
  if (n) rows = rows.filter((p) => [p.full_name, p.reg_id, p.nic, p.mobile].some((v) => (v || '').toLowerCase().includes(n)));
  res.json({ count: rows.length, patients: rows.map(patientOut) });
});

// CREATE - register a patient (no app login needed; admin manages records)
router.post('/patients', (req, res) => {
  const b = req.body || {};
  const e = validatePatient(b, true);
  if (Object.keys(e).length) return res.status(400).json({ error: 'Please fix the highlighted fields.', fields: e });
  const info = db.prepare(`INSERT INTO users (full_name, nic, age, gender, mobile, password_hash, role, blood_group, clinical_notes)
    VALUES (?,?,?,?,?,?, 'patient', ?, ?)`).run(
    b.full_name.trim(), String(b.nic).trim().toUpperCase(), Number(b.age), b.gender, normalizeMobile(b.mobile),
    bcrypt.hashSync(crypto.randomBytes(12).toString('hex'), 8), b.blood_group || 'Unknown', String(b.clinical_notes || '').slice(0, 1000));
  db.prepare('UPDATE users SET reg_id=? WHERE id=?').run('REG-' + String(info.lastInsertRowid).padStart(5, '0'), info.lastInsertRowid);
  res.status(201).json({ patient: patientRow(info.lastInsertRowid) });
});

// UPDATE (NIC cannot be changed after registration)
router.put('/patients/:id', (req, res) => {
  const cur = db.prepare(`SELECT * FROM users WHERE id=? AND role='patient'`).get(req.params.id);
  if (!cur) return res.status(404).json({ error: 'Patient not found.' });
  const b = { ...cur, ...req.body };
  const e = validatePatient(b, false, cur.id);
  if (Object.keys(e).length) return res.status(400).json({ error: 'Please fix the highlighted fields.', fields: e });
  db.prepare('UPDATE users SET full_name=?, age=?, gender=?, mobile=?, blood_group=?, clinical_notes=? WHERE id=?')
    .run(b.full_name.trim(), Number(b.age), b.gender, normalizeMobile(b.mobile), b.blood_group || 'Unknown', String(b.clinical_notes || '').slice(0, 1000), cur.id);
  res.json({ patient: patientRow(cur.id) });
});

// DELETE - blocked while upcoming bookings exist
router.delete('/patients/:id', (req, res) => {
  const p = patientRow(req.params.id);
  if (!p) return res.status(404).json({ error: 'Patient not found.' });
  if (p.upcoming_bookings > 0)
    return res.status(409).json({ error: `Cannot delete: ${p.upcoming_bookings} upcoming booking(s). Cancel them first.` });
  db.prepare('DELETE FROM users WHERE id=?').run(p.id);
  res.json({ ok: true });
});

module.exports = router;
