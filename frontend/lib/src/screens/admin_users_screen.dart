import 'package:flutter/material.dart';

import '../api/api_client.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
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
    } catch (_) {
      setState(() => _error = 'Không tải được users');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createUser() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String role = 'user';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Tạo user'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                    TextField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: role,
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('user')),
                        DropdownMenuItem(value: 'admin', child: Text('admin')),
                        DropdownMenuItem(value: 'staff', child: Text('staff')),
                      ],
                      onChanged: (v) => setStateDialog(() => role = v ?? 'user'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tạo')),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;

    await widget.api.postJson('/api/admin/users', {
      'name': nameCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'password': passwordCtrl.text,
      'role': role,
    });
    await _load();
  }

  Future<void> _updateRole(Map<String, dynamic> u) async {
    final id = u['id'];
    final currentRole = (u['role'] ?? 'user').toString();
    String nextRole = currentRole;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Cập nhật role'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: nextRole,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('user')),
                  DropdownMenuItem(value: 'admin', child: Text('admin')),
                      DropdownMenuItem(value: 'staff', child: Text('staff')),
                ],
                onChanged: (v) => setStateDialog(() => nextRole = v ?? 'user'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    await widget.api.putJson('/api/admin/users/$id', {'role': nextRole});
    await _load();
  }

  Future<void> _deleteUser(Map<String, dynamic> u) async {
    final id = u['id'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa user?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.api.deleteJson('/api/admin/users/$id');
    await _load();
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
          Row(
            children: [
              Text('Users', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              FilledButton.icon(onPressed: _createUser, icon: const Icon(Icons.add), label: const Text('New')),
            ],
          ),
          const SizedBox(height: 12),
          for (final u in _items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(u['name']?.toString() ?? '(no name)'),
                subtitle: Text(u['email']?.toString() ?? ''),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text((u['role'] ?? 'user').toString())),
                    IconButton(
                      tooltip: 'Edit role',
                      onPressed: () => _updateRole(u),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _deleteUser(u),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

