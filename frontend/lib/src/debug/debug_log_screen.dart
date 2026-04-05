import 'package:flutter/material.dart';

import 'debug_log.dart';

class DebugLogScreen extends StatelessWidget {
  const DebugLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug logs'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: DebugLog.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<DebugLogEntry>>(
        valueListenable: DebugLog.entries,
        builder: (context, entries, _) {
          if (entries.isEmpty) {
            return const Center(child: Text('Chưa có log'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            itemBuilder: (context, idx) {
              final e = entries[entries.length - 1 - idx];
              return Card(
                child: ListTile(
                  title: Text('[${e.tag}] ${e.message}'),
                  subtitle: Text(e.ts.toIso8601String()),
                  onTap: e.details == null
                      ? null
                      : () {
                          showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Details'),
                              content: SingleChildScrollView(child: Text(e.details.toString())),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                              ],
                            ),
                          );
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

