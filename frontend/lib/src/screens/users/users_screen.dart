import 'package:flutter/material.dart';

import '../../api/api_client.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await widget.api.getJson('/api/admin/users');
      final data = json['data'];
      final list = (data is List) ? data.cast<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
      setState(() => _items = list);
    } catch (e) {
      setState(() => _error = 'Không tải được users (cần quyền admin)');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 10),
            FilledButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Users', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: Text('Chưa có user nào')),
            ),
          for (final u in _items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(u['name']?.toString() ?? '(no name)'),
                subtitle: Text(u['email']?.toString() ?? ''),
                trailing: Text((u['role'] ?? '').toString()),
              ),
            ),
        ],
      ),
    );
  }
}

