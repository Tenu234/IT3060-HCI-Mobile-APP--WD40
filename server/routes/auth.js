// Patient Registration + Login + own-profile CRUD
const router = require('express').Router();
const bcrypt = require('bcryptjs');
const db = require('../db');
const { sign, requireAuth } = require('../middleware/auth');
const { normalizeMobile, isValidMobile, isValidNic, isIdentifierNic } = require('../utils');

const GENDERS = ['Male', 'Female', 'Other'];

const publicUser = (u) => ({
  id: u.id, reg_id: u.reg_id, full_name: u.full_name, nic: u.nic, age: u.age,
  gender: u.gender, mobile: u.mobile, role: u.role, blood_group: u.blood_group,
});

// CREATE - register a patient account
router.post('/register', (req, res) => {
  const { full_name, nic, age, gender, mobile, password, confirm_password, accepted_terms } = req.body || {};
  const errors = {};
  if (!full_name || String(full_name).trim().length < 3) errors.full_name = 'Enter your full name as shown on your NIC.';
  const nicClean = String(nic || '').trim().toUpperCase();
  if (!isValidNic(nicClean)) errors.nic = 'NIC must be 12 digits, or 9 digits followed by V/X.';
  const ageNum = Number(age);
  if (!Number.isInteger(ageNum) || ageNum < 0 || ageNum > 120) errors.age = 'Enter a valid age (0-120).';
  if (!GENDERS.includes(gender)) errors.gender = 'Select a gender.';
  const mob = normalizeMobile(mobile);
  if (!isValidMobile(mob)) errors.mobile = 'Enter a valid mobile, e.g. +94 77 123 4567.';
  if (!password || String(password).length < 8) errors.password = 'Password must be at least 8 characters.';
  else if (password !== confirm_password) errors.confirm_password = 'Passwords do not match.';
  if (!accepted_terms) errors.accepted_terms = 'You must agree to the Terms and Privacy Notice.';

  if (!errors.nic && db.prepare('SELECT 1 FROM users WHERE nic=?').get(nicClean)) errors.nic = 'This NIC is already registered. Please log in.';
  if (!errors.mobile && db.prepare('SELECT 1 FROM users WHERE mobile=?').get(mob)) errors.mobile = 'This mobile number is already registered.';
  if (Object.keys(errors).length) return res.status(400).json({ error: 'Please fix the highlighted fields.', fields: errors });

  const info = db.prepare(`INSERT INTO users (full_name, nic, age, gender, mobile, password_hash, role)
    VALUES (?,?,?,?,?,?, 'patient')`)
    .run(String(full_name).trim(), nicClean, ageNum, gender, mob, bcrypt.hashSync(password, 10));
  const regId = 'REG-' + String(info.lastInsertRowid).padStart(5, '0');
  db.prepare('UPDATE users SET reg_id=? WHERE id=?').run(regId, info.lastInsertRowid);
  const user = db.prepare('SELECT * FROM users WHERE id=?').get(info.lastInsertRowid);
  res.status(201).json({ token: sign(user), user: publicUser(user) });
});

// READ - login with NIC or mobile
router.post('/login', (req, res) => {
  const { identifier, password } = req.body || {};
  const bad = () => res.status(401).json({ error: 'NIC/mobile number or password is incorrect. Try again.' });
  if (!identifier || !password) return bad();
  const id = String(identifier).trim();
  const user = isIdentifierNic(id)
    ? db.prepare('SELECT * FROM users WHERE nic = ?').get(id.toUpperCase())
    : db.prepare('SELECT * FROM users WHERE mobile = ?').get(normalizeMobile(id));
  if (!user || !bcrypt.compareSync(String(password), user.password_hash)) return bad();
  res.json({ token: sign(user), user: publicUser(user) });
});

router.get('/me', requireAuth, (req, res) => res.json({ user: publicUser(req.user) }));

// UPDATE - edit own profile
router.put('/me', requireAuth, (req, res) => {
  const { full_name, age, gender, mobile } = req.body || {};
  const errors = {};
  if (!full_name || String(full_name).trim().length < 3) errors.full_name = 'Enter your full name.';
  const ageNum = Number(age);
  if (!Number.isInteger(ageNum) || ageNum < 0 || ageNum > 120) errors.age = 'Enter a valid age.';
  if (!GENDERS.includes(gender)) errors.gender = 'Select a gender.';
  const mob = normalizeMobile(mobile);
  if (!isValidMobile(mob)) errors.mobile = 'Enter a valid mobile number.';
  else if (db.prepare('SELECT 1 FROM users WHERE mobile=? AND id<>?').get(mob, req.user.id)) errors.mobile = 'Mobile number already in use.';
  if (Object.keys(errors).length) return res.status(400).json({ error: 'Please fix the highlighted fields.', fields: errors });
  db.prepare('UPDATE users SET full_name=?, age=?, gender=?, mobile=? WHERE id=?')
    .run(String(full_name).trim(), ageNum, gender, mob, req.user.id);
  res.json({ user: publicUser(db.prepare('SELECT * FROM users WHERE id=?').get(req.user.id)) });
});

// UPDATE - change password
router.put('/me/password', requireAuth, (req, res) => {
  const { current_password, new_password } = req.body || {};
  if (!bcrypt.compareSync(String(current_password || ''), req.user.password_hash))
    return res.status(400).json({ error: 'Current password is incorrect.' });
  if (!new_password || String(new_password).length < 8)
    return res.status(400).json({ error: 'New password must be at least 8 characters.' });
  db.prepare('UPDATE users SET password_hash=? WHERE id=?').run(bcrypt.hashSync(new_password, 10), req.user.id);
  res.json({ ok: true });
});

// DELETE - delete own account
router.delete('/me', requireAuth, (req, res) => {
  if (req.user.role !== 'patient') return res.status(403).json({ error: 'Only patient accounts can be self-deleted.' });
  db.prepare('DELETE FROM users WHERE id=?').run(req.user.id);
  res.json({ ok: true });
});

module.exports = router;
