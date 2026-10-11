import 'package:flutter/material.dart';
import '../router.dart';
import '../services/auth.dart';
import '../theme.dart';

/// Avatar with initials + "Log out" menu, used in admin app bars.
class AdminMenuButton extends StatelessWidget {
  const AdminMenuButton({super.key});

  String get _initials {
    final parts = '${Auth.i.user?['full_name'] ?? 'A'}'.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      onSelected: (v) {
        if (v == 'logout') doLogout(context);
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text('${Auth.i.user?['full_name'] ?? 'Admin'}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
        ),
        const PopupMenuItem<String>(value: 'logout', child: Text('Log out')),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: C.ink,
          child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      ),
    );
  }
}
