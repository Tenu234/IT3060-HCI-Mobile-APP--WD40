// Shared helpers: date handling, validation, session status.

function todayStr(d = new Date()) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function addDays(dateStr, n) {
  const d = new Date(dateStr + 'T00:00:00');
  d.setDate(d.getDate() + n);
  return todayStr(d);
}

// Accepts 0771234567, 771234567, +94771234567, +94 77 123 4567 -> +94771234567
function normalizeMobile(input) {
  if (!input) return '';
  let s = String(input).replace(/[\s-]/g, '');
  if (s.startsWith('+94')) s = s.slice(3);
  else if (s.startsWith('94') && s.length === 11) s = s.slice(2);
  else if (s.startsWith('0')) s = s.slice(1);
  return '+94' + s;
}

const isValidMobile = (m) => /^\+94\d{9}$/.test(m);
// Old NIC: 9 digits + V/X. New NIC: 12 digits.
const isValidNic = (n) => /^(\d{9}[VvXx]|\d{12})$/.test(n);
const isValidTime = (t) => /^([01]\d|2[0-3]):[0-5]\d$/.test(t);
const isValidDate = (d) => /^\d{4}-\d{2}-\d{2}$/.test(d) && !isNaN(new Date(d).getTime());

function isIdentifierNic(x) {
  return isValidNic(String(x).trim());
}

// Computed status shown in the UI.
function sessionStatus(s) {
  if (s.status === 'closed') return 'Closed';
  const today = todayStr();
  if (s.date < today) return 'Completed';
  if (s.booked >= s.max_appointments) return 'Full';
  if (s.date > today) return 'Upcoming';
  return 'Active';
}

function maskNic(nic) {
  if (!nic) return '';
  return '\u2022'.repeat(Math.max(nic.length - 4, 0)) + nic.slice(-4);
}

module.exports = {
  todayStr, addDays, normalizeMobile, isValidMobile, isValidNic,
  isValidTime, isValidDate, isIdentifierNic, sessionStatus, maskNic,
};
