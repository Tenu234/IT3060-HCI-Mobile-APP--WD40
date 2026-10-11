import 'package:flutter/foundation.dart';

/// Backend base URL.
/// - Chrome / Windows / iOS simulator -> http://localhost:3000
/// - Android emulator                  -> http://10.0.2.2:3000
/// - Real phone on same Wi-Fi          -> set [lanOverride] to your PC IP, e.g. 'http://192.168.1.10:3000'
const String? lanOverride = null;

String get apiBase {
  if (lanOverride != null) return lanOverride!;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}
