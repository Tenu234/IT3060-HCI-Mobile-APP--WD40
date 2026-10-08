// SQLite database: schema + demo seed data (fictional data only).
const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const path = require('path');
const { todayStr, addDays } = require('./utils');

const dbPath = process.env.DB_PATH || path.join(__dirname, 'opd.db');
const db = new Database(dbPath);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  reg_id        TEXT UNIQUE,
  full_name     TEXT NOT NULL,
  nic           TEXT NOT NULL UNIQUE,
  age           INTEGER,
  gender        TEXT,
  mobile        TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'patient' CHECK (role IN ('patient','staff','admin')),
  blood_group   TEXT DEFAULT 'Unknown',
  clinical_notes TEXT DEFAULT '',
  created_at    TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clinics (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  hospital    TEXT NOT NULL,
  name        TEXT NOT NULL,
  code        TEXT NOT NULL,
  district    TEXT NOT NULL,
  room        TEXT,
  doctor      TEXT,
  description TEXT,
  days        TEXT DEFAULT 'Mon-Sat',
  open_time   TEXT,
  close_time  TEXT
);

CREATE TABLE IF NOT EXISTS sessions (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  clinic_id        INTEGER NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  room             TEXT NOT NULL,
  doctor           TEXT NOT NULL,
  date             TEXT NOT NULL,
  start_time       TEXT NOT NULL,
  end_time         TEXT NOT NULL,
  max_appointments INTEGER NOT NULL CHECK (max_appointments > 0),
  status           TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','closed'))
);

CREATE TABLE IF NOT EXISTS appointments (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  token      TEXT NOT NULL,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  status     TEXT NOT NULL DEFAULT 'booked' CHECK (status IN ('booked','completed','cancelled')),
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS favorites (
  user_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  clinic_id INTEGER NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, clinic_id)
);
`);

function seed() {
  if (db.prepare('SELECT COUNT(*) c FROM users').get().c > 0) return;

  const hash = (p) => bcrypt.hashSync(p, 10);
  const insUser = db.prepare(`INSERT INTO users
    (reg_id, full_name, nic, age, gender, mobile, password_hash, role, blood_group, clinical_notes)
    VALUES (?,?,?,?,?,?,?,?,?,?)`);

  insUser.run('ADM-0001', 'Nimal Jayasinghe', '198011111111', 46, 'Male', '+94711111111', hash('Admin@123'), 'admin', 'A+', '');
  insUser.run('STF-0001', 'Kumari Silva', '199022222222', 36, 'Female', '+94722222222', hash('Staff@123'), 'staff', 'B+', '');
  insUser.run('REG-02481', 'K. A. Sunimal Perera', '199812345678', 28, 'Male', '+94771234567', hash('Patient@123'), 'patient', 'O+', 'Mild asthma. Review in 3 months.');

  const insClinic = db.prepare(`INSERT INTO clinics
    (hospital, name, code, district, room, doctor, description, days, open_time, close_time)
    VALUES (?,?,?,?,?,?,?,?,?,?)`);
  insClinic.run('National Hospital of Sri Lanka', 'General OPD', 'A', 'Colombo', 'Room 14', 'Dr. Nadeesha Fernando', 'General assessment and treatment for adult outpatients.', 'Mon-Sat', '08:00', '16:30');
  insClinic.run('Teaching Hospital Kandy', 'Dental', 'D', 'Kandy', 'Room 08', 'Dr. Silva', 'Dental examination, extractions and oral health advice.', 'Mon-Fri', '08:00', '14:00');
  insClinic.run('Karapitiya Teaching Hospital', 'Pediatrics', 'P', 'Galle', 'Room 21', 'Dr. Perera', 'Child health, vaccinations and growth monitoring.', 'Mon-Sat', '08:30', '15:30');
  insClinic.run('Colombo South Teaching Hospital', 'Eye Clinic', 'E', 'Colombo', 'Room 05', 'Dr. Rathnayake', 'Vision tests, eye infections and follow-up care.', 'Mon-Fri', '09:00', '15:00');

  const insSession = db.prepare(`INSERT INTO sessions
    (clinic_id, room, doctor, date, start_time, end_time, max_appointments, status) VALUES (?,?,?,?,?,?,?,?)`);
  const today = todayStr();
  const slots = [['08:00', '10:00', 20], ['10:00', '12:00', 20], ['12:30', '14:30', 20], ['14:30', '16:30', 20]];
  for (let c = 1; c <= 4; c++) {
    const clinic = db.prepare('SELECT * FROM clinics WHERE id=?').get(c);
    for (let d = 0; d < 7; d++) {
      const date = addDays(today, d);
      for (const [s, e, m] of slots) {
        if (s >= clinic.close_time) continue;
        insSession.run(c, clinic.room, clinic.doctor, date, s, e, m, 'active');
      }
    }
  }
  // Past sessions used for demo patient visit history.
  const past1 = insSession.run(1, 'Room 14', 'Dr. Perera', addDays(today, -26), '08:00', '12:00', 40, 'active').lastInsertRowid;
  const past2 = insSession.run(2, 'Room 08', 'Dr. Silva', addDays(today, -51), '09:00', '13:00', 24, 'active').lastInsertRowid;
  const insAppt = db.prepare('INSERT INTO appointments (token, user_id, session_id, status) VALUES (?,?,?,?)');
  insAppt.run('A-084', 3, past1, 'completed');
  insAppt.run('D-031', 3, past2, 'completed');

  // Make session #2 (10:00-12:00 today) full for the "Full" slot demo.
  db.prepare('UPDATE sessions SET max_appointments = 1 WHERE id = 2').run();
  insAppt.run('A-001', 3, 2, 'booked');
}

seed();
module.exports = db;
