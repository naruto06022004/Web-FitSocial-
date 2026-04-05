import 'dart:collection';

import 'package:flutter/foundation.dart';

class DebugLogEntry {
  DebugLogEntry({
    required this.ts,
    required this.tag,
    required this.message,
    this.details,
  });

  final DateTime ts;
  final String tag;
  final String message;
  final Object? details;
}

class DebugLog {
  static final ValueNotifier<List<DebugLogEntry>> entries = ValueNotifier<List<DebugLogEntry>>(<DebugLogEntry>[]);

  static void add(String tag, String message, {Object? details}) {
    final next = List<DebugLogEntry>.from(entries.value);
    next.add(DebugLogEntry(ts: DateTime.now(), tag: tag, message: message, details: details));
    // keep last 300
    if (next.length > 300) {
      final trimmed = next.sublist(next.length - 300);
      entries.value = UnmodifiableListView(trimmed);
    } else {
      entries.value = UnmodifiableListView(next);
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print('[$tag] $message');
      if (details != null) {
        // ignore: avoid_print
        print(details);
      }
    }
  }

  static void clear() => entries.value = const <DebugLogEntry>[];
}

