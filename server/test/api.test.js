// Run: npm test   (uses a temporary database, does not touch opd.db)
process.env.DB_PATH = require('path').join(require('os').tmpdir(), `opd_test_${Date.now()}.db`);
const assert = require('assert');
const app = require('../index');
const { todayStr, addDays } = require('../utils');

let passed = 0, failed = 0;
const server = app.listen(0);
const base = `http://localhost:${server.address().port}`;

async function call(method, path, body, token) {
  const r = await fetch(base + path, {
    method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + token } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: r.status, body: await r.json() };
}
async function t(id, name, fn) {
  try { await fn(); passed++; console.log(`PASS  ${id}  ${name}`); }
  catch (e) { failed++; console.log(`FAIL  ${id}  ${name}\n      ${e.message}`); }
}

(async () => {
  const admin = (await call('POST', '/api/auth/login', { identifier: '198011111111', password: 'Admin@123' })).body.token;
  const staff = (await call('POST', '/api/auth/login', { identifier: '+94722222222', password: 'Staff@123' })).body.token;
  let patient, patientId;

  // ---- Patient registration ----
  await t('TC-REG-01', 'Register with valid data (Create)', async () => {
    const r = await call('POST', '/api/auth/register', { full_name: 'Test Patient One', nic: '200012345678', age: 25, gender: 'Female', mobile: '+94 77 765 4321', password: 'Passw0rd!', confirm_password: 'Passw0rd!', accepted_terms: true });
    assert.strictEqual(r.status, 201); assert(r.body.token); assert.strictEqual(r.body.user.mobile, '+94777654321');
    patient = r.body.token; patientId = r.body.user.id;
  });
  await t('TC-REG-02', 'Duplicate NIC rejected', async () => {
    const r = await call('POST', '/api/auth/register', { full_name: 'Another Person', nic: '200012345678', age: 30, gender: 'Male', mobile: '+94770000001', password: 'Passw0rd!', confirm_password: 'Passw0rd!', accepted_terms: true });
    assert.strictEqual(r.status, 400); assert(r.body.fields.nic);
  });
  await t('TC-REG-03', 'Invalid fields return per-field errors', async () => {
    const r = await call('POST', '/api/auth/register', { full_name: '', nic: '123', age: 'x', mobile: '12', password: 'short', confirm_password: 'nope' });
    assert.strictEqual(r.status, 400);
    for (const k of ['full_name', 'nic', 'age', 'gender', 'mobile', 'password', 'accepted_terms']) assert(r.body.fields[k], k);
  });
  await t('TC-REG-04', 'Password mismatch rejected', async () => {
    const r = await call('POST', '/api/auth/register', { full_name: 'Mismatch Test', nic: '200112345678', age: 20, gender: 'Male', mobile: '+94770000002', password: 'Passw0rd!', confirm_password: 'Different1', accepted_terms: true });
    assert(r.body.fields.confirm_password);
  });
  await t('TC-LOG-01', 'Login by NIC (Read)', async () => {
    assert.strictEqual((await call('POST', '/api/auth/login', { identifier: '200012345678', password: 'Passw0rd!' })).status, 200);
  });
  await t('TC-LOG-02', 'Login by mobile (0-prefix accepted)', async () => {
    assert.strictEqual((await call('POST', '/api/auth/login', { identifier: '0777654321', password: 'Passw0rd!' })).status, 200);
  });
  await t('TC-LOG-03', 'Wrong password shows generic error', async () => {
    const r = await call('POST', '/api/auth/login', { identifier: '200012345678', password: 'wrong' });
    assert.strictEqual(r.status, 401); assert(/incorrect/.test(r.body.error));
  });
  await t('TC-PRO-01', 'Update own profile (Update)', async () => {
    const r = await call('PUT', '/api/auth/me', { full_name: 'Test Patient Updated', age: 26, gender: 'Female', mobile: '+94777654321' }, patient);
    assert.strictEqual(r.status, 200); assert.strictEqual(r.body.user.age, 26);
  });
  await t('TC-AUTH-01', 'Protected route without token = 401', async () => {
    assert.strictEqual((await call('GET', '/api/clinics')).status, 401);
  });

  // ---- OPD search ----
  await t('TC-SRCH-01', 'List all clinics (Read)', async () => {
    const r = await call('GET', '/api/clinics', null, patient); assert.strictEqual(r.body.count, 4);
  });
  await t('TC-SRCH-02', 'Search by text', async () => {
    const r = await call('GET', '/api/clinics?q=kandy', null, patient); assert.strictEqual(r.body.count, 1);
  });
  await t('TC-SRCH-03', 'Filter by district + clinic type', async () => {
    const r = await call('GET', '/api/clinics?district=Colombo&clinic=Eye%20Clinic', null, patient); assert.strictEqual(r.body.count, 1);
  });
  await t('TC-SRCH-04', 'Open-today filter', async () => {
    const r = await call('GET', '/api/clinics?openToday=true', null, patient); assert(r.body.count >= 1);
  });
  await t('TC-SRCH-05', 'No result search returns empty list', async () => {
    const r = await call('GET', '/api/clinics?q=zzzz', null, patient); assert.strictEqual(r.body.count, 0);
  });
  await t('TC-SRCH-06', 'Save + unsave clinic (Create/Delete)', async () => {
    assert.strictEqual((await call('POST', '/api/clinics/1/favorite', null, patient)).status, 201);
    assert.strictEqual((await call('GET', '/api/clinics?saved=true', null, patient)).body.count, 1);
    await call('DELETE', '/api/clinics/1/favorite', null, patient);
    assert.strictEqual((await call('GET', '/api/clinics?saved=true', null, patient)).body.count, 0);
  });
  let slots;
  await t('TC-SLOT-01', 'View slots for a clinic incl. a Full slot', async () => {
    const r = await call('GET', '/api/clinics/1', null, patient); slots = r.body.slots;
    assert(slots.length > 0); assert(slots.some((s) => s.full)); assert(slots.some((s) => !s.full));
  });

  // ---- Booking integration ----
  let apptId;
  await t('TC-BOOK-01', 'Book an available slot', async () => {
    const free = slots.find((s) => !s.full);
    const r = await call('POST', '/api/appointments', { session_id: free.id }, patient);
    assert.strictEqual(r.status, 201); assert(r.body.appointment.token); apptId = r.body.appointment.id;
  });
  await t('TC-BOOK-02', 'Full slot cannot be booked', async () => {
    const full = slots.find((s) => s.full);
    assert.strictEqual((await call('POST', '/api/appointments', { session_id: full.id }, patient)).status, 409);
  });
  await t('TC-BOOK-03', 'Cancel own appointment', async () => {
    const r = await call('PUT', `/api/appointments/${apptId}/cancel`, null, patient);
    assert.strictEqual(r.body.appointment.status, 'cancelled');
  });

  // ---- Staff patient search ----
  await t('TC-STF-01', 'Staff search by NIC returns masked NIC + visits', async () => {
    const r = await call('GET', '/api/patients/search?q=199812345678', null, staff);
    assert.strictEqual(r.status, 200); assert(r.body.patient.nic_masked.endsWith('5678')); assert(!r.body.patient.nic_masked.includes('1998')); assert(r.body.visits.length >= 2);
  });
  await t('TC-STF-02', 'Staff search by registration ID', async () => {
    assert.strictEqual((await call('GET', '/api/patients/search?q=REG-02481', null, staff)).status, 200);
  });
  await t('TC-STF-03', 'Unknown patient = 404', async () => {
    assert.strictEqual((await call('GET', '/api/patients/search?q=000000000000', null, staff)).status, 404);
  });
  await t('TC-STF-04', 'Patient role cannot use patient search (403)', async () => {
    assert.strictEqual((await call('GET', '/api/patients/search?q=REG-02481', null, patient)).status, 403);
  });
  await t('TC-STF-05', 'Staff updates clinical details (Update)', async () => {
    const r = await call('PUT', `/api/patients/${patientId}`, { blood_group: 'B+', clinical_notes: 'Test note' }, staff);
    assert.strictEqual(r.body.patient.blood_group, 'B+');
  });
  await t('TC-STF-06', 'Admin profile + history view', async () => {
    const r = await call('GET', '/api/patients/3', null, admin); assert.strictEqual(r.body.patient.reg_id, 'REG-02481');
  });

  // ---- Admin OPD sessions CRUD ----
  let sid;
  const newSession = { clinic_id: 1, room: 'Room 99', doctor: 'Dr. Test', date: addDays(todayStr(), 3), start_time: '17:00', end_time: '19:00', max_appointments: 10 };
  await t('TC-ADM-01', 'List sessions + summary (Read)', async () => {
    const r = await call('GET', `/api/sessions?date=${todayStr()}`, null, admin);
    assert.strictEqual(r.status, 200); assert(r.body.sessions.length > 0); assert(r.body.summary.booked_appointments >= 1);
  });
  await t('TC-ADM-02', 'Create session', async () => {
    const r = await call('POST', '/api/sessions', newSession, admin);
    assert.strictEqual(r.status, 201); sid = r.body.session.id;
  });
  await t('TC-ADM-03', 'Create validates fields (end before start)', async () => {
    const r = await call('POST', '/api/sessions', { ...newSession, end_time: '16:00' }, admin);
    assert.strictEqual(r.status, 400); assert(r.body.fields.end_time);
  });
  await t('TC-ADM-04', 'Room clash rejected', async () => {
    assert.strictEqual((await call('POST', '/api/sessions', newSession, admin)).status, 409);
  });
  await t('TC-ADM-05', 'Edit session (Update)', async () => {
    const r = await call('PUT', `/api/sessions/${sid}`, { ...newSession, max_appointments: 15 }, admin);
    assert.strictEqual(r.body.session.max_appointments, 15);
  });
  await t('TC-ADM-06', 'Edit with bookings requires confirmation', async () => {
    const p = await call('POST', '/api/appointments', { session_id: sid }, patient);
    assert.strictEqual(p.status, 201);
    const r1 = await call('PUT', `/api/sessions/${sid}`, { ...newSession, doctor: 'Dr. Changed' }, admin);
    assert.strictEqual(r1.status, 409); assert(r1.body.needs_confirmation);
    const r2 = await call('PUT', `/api/sessions/${sid}`, { ...newSession, doctor: 'Dr. Changed', confirm: true }, admin);
    assert.strictEqual(r2.status, 200);
  });
  await t('TC-ADM-07', 'Capacity below booked count rejected', async () => {
    const r = await call('PUT', `/api/sessions/${sid}`, { ...newSession, doctor: 'Dr. Changed', max_appointments: 1 }, admin);
    assert.strictEqual(r.status, 200); // 1 booking, cap 1 is allowed
    const r2 = await call('PUT', `/api/sessions/${sid}`, { ...newSession, doctor: 'Dr. Changed', max_appointments: 0 }, admin);
    assert.strictEqual(r2.status, 400);
  });
  await t('TC-ADM-08', 'Delete blocked when bookings exist', async () => {
    assert.strictEqual((await call('DELETE', `/api/sessions/${sid}`, null, admin)).status, 409);
  });
  await t('TC-ADM-09', 'Close session needs confirm, then cancels bookings', async () => {
    assert.strictEqual((await call('PATCH', `/api/sessions/${sid}/close`, {}, admin)).status, 409);
    const r = await call('PATCH', `/api/sessions/${sid}/close`, { confirm: true }, admin);
    assert.strictEqual(r.body.session.display_status, 'Closed'); assert.strictEqual(r.body.session.booked, 0);
  });
  await t('TC-ADM-10', 'Reopen session', async () => {
    const r = await call('PATCH', `/api/sessions/${sid}/reopen`, null, admin);
    assert.notStrictEqual(r.body.session.display_status, 'Closed');
  });
  await t('TC-ADM-11', 'Delete empty session (Delete)', async () => {
    assert.strictEqual((await call('DELETE', `/api/sessions/${sid}`, null, admin)).status, 200);
    assert.strictEqual((await call('GET', `/api/sessions/${sid}`, null, admin)).status, 404);
  });
  await t('TC-ADM-12', 'Staff/patient cannot access admin sessions (403)', async () => {
    assert.strictEqual((await call('GET', '/api/sessions', null, staff)).status, 403);
    assert.strictEqual((await call('GET', '/api/sessions', null, patient)).status, 403);
  });
  await t('TC-ADM-13', 'Filter sessions by status', async () => {
    const r = await call('GET', '/api/sessions?status=Full', null, admin);
    assert(r.body.sessions.every((s) => s.display_status === 'Full'));
  });
  await t('TC-PRO-02', 'Delete own account (Delete)', async () => {
    assert.strictEqual((await call('DELETE', '/api/auth/me', null, patient)).status, 200);
    assert.strictEqual((await call('GET', '/api/auth/me', null, patient)).status, 401);
  });

  console.log(`\n${passed} passed, ${failed} failed`);
  server.close();
  process.exit(failed ? 1 : 0);
})();
