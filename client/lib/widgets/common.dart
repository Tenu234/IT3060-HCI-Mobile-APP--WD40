import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

// ---------- date helpers ----------
DateTime parseDate(String s) => DateTime.parse('${s}T00:00:00');
String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String chipDate(String s) => DateFormat('EEE dd MMM').format(parseDate(s));
String longDate(String s) => DateFormat('dd MMM yyyy').format(parseDate(s));
String fullDate(String s) => DateFormat('EEE dd MMM yyyy').format(parseDate(s));
String hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

void snack(BuildContext c, String m, {bool error = false}) {
  ScaffoldMessenger.of(c).hideCurrentSnackBar();
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text(m),
    backgroundColor: error ? C.red : C.ink,
    behavior: SnackBarBehavior.floating,
  ));
}

Future<bool> confirmDialog(BuildContext c,
    {required String title,
    required String message,
    String confirm = 'Confirm',
    bool danger = false}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm, style: TextStyle(color: danger ? C.red : C.brand, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return r ?? false;
}

// ---------- app bar ----------
class OpdAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool showBack;
  const OpdAppBar({
    super.key,
    this.title = 'Government Hospital OPD',
    this.subtitle = 'Patient Services',
    this.actions = const [],
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && Navigator.of(context).canPop();
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      leading: canPop ? const BackButton() : null,
      titleSpacing: canPop ? 0 : 16,
      title: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: C.muted)),
          ]),
        ),
      ]),
      actions: [
        ...actions,
        IconButton(
          tooltip: 'Help',
          icon: const Icon(Icons.help_outline, color: C.muted),
          onPressed: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Need help?'),
              content: const Text(
                  'Use your NIC or +94 mobile number to log in.\nOPD queue numbers are assigned only after a booking is confirmed.\nFor assistance, contact the hospital help desk.\n\nFictional demo data only.'),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: C.border),
      ),
    );
  }
}

// ---------- layout ----------
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.borderColor = C.border,
  });
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: child,
      );
}

class Heading extends StatelessWidget {
  final String title;
  final String? subtitle;
  const Heading(this.title, {super.key, this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: const TextStyle(fontSize: 15, color: C.muted)),
        ],
      ]);
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: C.redSoft, borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded, color: C.red, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: C.red, fontSize: 14))),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: C.muted),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      );
}

// ---------- buttons ----------
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton(this.label, {super.key, this.onPressed, this.loading = false});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: C.brand,
            disabledBackgroundColor: const Color(0xFFA9C3F5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color? fill;
  const SecondaryButton(this.label, {super.key, this.onPressed, this.color = C.brand, this.fill});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: fill ?? Colors.white,
            foregroundColor: color,
            side: BorderSide(color: fill != null ? Colors.transparent : C.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
}

// ---------- chips ----------
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    Color fg, bg;
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
      case 'available':
        fg = C.green; bg = C.greenSoft; break;
      case 'full':
      case 'cancelled':
        fg = C.red; bg = C.redSoft; break;
      case 'upcoming':
      case 'booked':
      case 'selected':
        fg = C.brand; bg = C.blueSoft; break;
      default:
        fg = C.grey; bg = C.greySoft;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: fg),
        const SizedBox(width: 6),
        Text(status, style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color? dot;
  final VoidCallback onTap;
  const FilterPill({super.key, required this.label, required this.onTap, this.active = false, this.dot});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? C.blueSoft : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? C.brand : C.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle, size: 9, color: dot ?? (active ? C.brand : C.muted)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? C.brand : C.ink)),
          ]),
        ),
      );
}

// ---------- form fields ----------
class LabeledField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? error;
  final bool password;
  final TextInputType? keyboard;
  final String? prefix;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffix;
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.password = false,
    this.keyboard,
    this.prefix,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.suffix,
  });
  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  bool _hide = true;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 8),
      TextField(
        controller: widget.controller,
        obscureText: widget.password && _hide,
        keyboardType: widget.keyboard,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: widget.error,
          errorStyle: const TextStyle(color: C.red, fontSize: 13),
          prefixText: widget.prefix == null ? null : '${widget.prefix}  ',
          prefixStyle: const TextStyle(color: C.ink, fontWeight: FontWeight.w600, fontSize: 16),
          suffixIcon: widget.password
              ? IconButton(
                  tooltip: _hide ? 'Show password' : 'Hide password',
                  icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: C.muted),
                  onPressed: () => setState(() => _hide = !_hide),
                )
              : widget.suffix,
        ),
      ),
    ]);
  }
}

/// Tap-to-choose field (bottom sheet). Avoids version-specific Dropdown APIs.
class SelectField extends StatelessWidget {
  final String? label;
  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? error;
  final IconData? leading;
  const SelectField({
    super.key,
    this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint = 'Select',
    this.error,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final field = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final r = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
            child: ListView(shrinkWrap: true, children: [
              for (final o in options)
                ListTile(
                  title: Text(o, style: TextStyle(fontWeight: o == value ? FontWeight.w800 : FontWeight.w500)),
                  trailing: o == value ? const Icon(Icons.check, color: C.brand) : null,
                  onTap: () => Navigator.pop(ctx, o),
                ),
            ]),
          ),
        );
        if (r != null) onChanged(r);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: error != null ? C.red : C.border, width: 1.2),
        ),
        child: Row(children: [
          if (leading != null) ...[Icon(leading, size: 20, color: C.muted), const SizedBox(width: 8)],
          Expanded(
            child: Text(value ?? hint,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, color: value == null ? C.muted : C.ink)),
          ),
          const Icon(Icons.keyboard_arrow_down, color: C.muted),
        ]),
      ),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label != null) ...[
        Text(label!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
      ],
      field,
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(error!, style: const TextStyle(color: C.red, fontSize: 13)),
        ),
    ]);
  }
}

class KeyValueRow extends StatelessWidget {
  final String k;
  final String v;
  final bool boxed;
  const KeyValueRow(this.k, this.v, {super.key, this.boxed = false});
  @override
  Widget build(BuildContext context) {
    final row = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: const TextStyle(color: C.muted, fontSize: 14)),
      const SizedBox(width: 12),
      Flexible(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
    ]);
    if (!boxed) return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: row);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(10)),
      child: row,
    );
  }
}
