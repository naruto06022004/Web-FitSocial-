import 'package:flutter/foundation.dart';

class FitnetConfig {
  /// For Android emulator use `http://10.0.2.2:8000`
  /// For real device (same Wi‑Fi) use your PC LAN IP, e.g. `http://192.168.1.10:8000`
  static String get apiBaseUrl {
    // Flutter Web / Desktop (calls localhost directly)
    if (kIsWeb) return 'http://127.0.0.1:8000';

    // Android emulator -> host machine
    return 'http://10.0.2.2:8000';
  }
}

