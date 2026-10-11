import 'package:flutter/material.dart';

// ── Brand colours ──────────────────────────────────────────────────────────
const kPrimary    = Color(0xFF006D77);
const kPrimaryDark= Color(0xFF004D56);
const kAccent     = Color(0xFF83C5BE);
const kSurface    = Color(0xFFF5F7FA);
const kCard       = Colors.white;
const kText       = Color(0xFF1A1A2E);
const kTextMuted  = Color(0xFF6B7280);

// Status colours
const kWaiting    = Color(0xFFF59E0B);
const kActive     = Color(0xFF3B82F6);
const kDone       = Color(0xFF10B981);
const kCancelled  = Color(0xFFEF4444);

// ── Text styles ─────────────────────────────────────────────────────────────
const kTitleStyle = TextStyle(
  fontSize: 22, fontWeight: FontWeight.bold, color: kText,
);
const kSubtitleStyle = TextStyle(
  fontSize: 13, color: kTextMuted,
);
const kLabelStyle = TextStyle(
  fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted,
  letterSpacing: 0.5,
);

// ── Decoration helpers ───────────────────────────────────────────────────────
BoxDecoration kCardDecoration({double radius = 16, Color? color}) => BoxDecoration(
  color: color ?? kCard,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: const [
    BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
  ],
);

InputDecoration kInputDecoration({
  required String label,
  required IconData icon,
  Widget? suffix,
}) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kPrimary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      labelStyle: const TextStyle(color: kTextMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kCancelled),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kCancelled, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

// ── Status helpers ───────────────────────────────────────────────────────────
Color statusColor(String s) {
  switch (s) {
    case 'waiting':
    case 'waiting_room':
    case 'entered_opd':  return kWaiting;
    case 'in_consultation': return kActive;
    case 'completed':    return kDone;
    case 'cancelled':
    case 'absent':       return kCancelled;
    default:             return kTextMuted;
  }
}

String statusLabel(String s) =>
    s.replaceAll('_', ' ').split(' ').map((w) =>
        w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

IconData statusIcon(String s) {
  switch (s) {
    case 'entered_opd':     return Icons.login_rounded;
    case 'waiting_room':    return Icons.hourglass_top_rounded;
    case 'in_consultation': return Icons.medical_services_rounded;
    case 'completed':       return Icons.check_circle_rounded;
    case 'absent':          return Icons.person_off_rounded;
    case 'cancelled':       return Icons.cancel_rounded;
    default:                return Icons.circle_rounded;
  }
}
