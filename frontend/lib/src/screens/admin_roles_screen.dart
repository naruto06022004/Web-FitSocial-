import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../ui/fitnet_layout.dart';

class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({
    super.key,
    required this.api,
    this.onAfterRoleCreated,
  });

  final ApiClient api;

  /// Called after a **new** role is saved successfully (e.g. navigate to User Management).
  final VoidCallback? onAfterRoleCreated;

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
  bool _loading = true;
  String? _error;
  String? _schemaHint;
  List<Map<String, dynamic>> _roles = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _schemaHint = null;
    });
    try {
      final json = await widget.api.getJson('/api/admin/roles');
      final data = json['data'];
      final list = (data is List) ? data.cast<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
      final meta = json['meta'];
      String? hint;
      if (meta is Map) {
        final incomplete = meta['schema_incomplete'];
        if (incomplete == true) {
          hint = (meta['hint'] ?? 'Run php artisan migrate (backend/laravel).').toString();
        }
      }
      setState(() {
        _roles = list;
        _schemaHint = hint;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editRole({Map<String, dynamic>? role}) async {
    final isNew = role == null;
    final keyCtrl = TextEditingController(text: (role?['key'] ?? '').toString());
    final labelCtrl = TextEditingController(text: (role?['label'] ?? '').toString());

    bool adminAccess = (role?['permissions']?['admin_access'] ?? false) == true;
    bool rolesManage = (role?['permissions']?['roles_manage'] ?? false) == true;
    bool usersManage = (role?['permissions']?['users_manage'] ?? false) == true;
    bool postsManage = (role?['permissions']?['posts_manage'] ?? false) == true;
    bool exercisesManage = (role?['permissions']?['exercises_manage'] ?? false) == true;
    bool rankingManage = (role?['permissions']?['ranking_manage'] ?? false) == true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isNew ? 'Add Role' : 'Edit Role'),
            content: SizedBox(
              width: (MediaQuery.sizeOf(context).width - 48).clamp(280.0, 520),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: keyCtrl,
                      enabled: isNew,
                      decoration: const InputDecoration(
                        labelText: 'Key (e.g. moderator)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Label (e.g. Moderator)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Permissions', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: adminAccess,
                      onChanged: (v) => setStateDialog(() => adminAccess = v),
                      title: const Text('admin_access'),
                      subtitle: const Text('Cho phép vào Admin Dashboard (/api/admin/*)'),
                    ),
                    SwitchListTile(
                      value: usersManage,
                      onChanged: (v) => setStateDialog(() => usersManage = v),
                      title: const Text('users_manage'),
                      subtitle: const Text('Quản lý users (tạo/sửa/xoá/portfolio)'),
                    ),
                    SwitchListTile(
                      value: postsManage,
                      onChanged: (v) => setStateDialog(() => postsManage = v),
                      title: const Text('posts_manage'),
                      subtitle: const Text('Quản lý posts'),
                    ),
                    SwitchListTile(
                      value: exercisesManage,
                      onChanged: (v) => setStateDialog(() => exercisesManage = v),
                      title: const Text('exercises_manage'),
                      subtitle: const Text('Quản lý Exercises (duyệt, chỉnh MET/coeff)'),
                    ),
                    SwitchListTile(
                      value: rankingManage,
                      onChanged: (v) => setStateDialog(() => rankingManage = v),
                      title: const Text('ranking_manage'),
                      subtitle: const Text('Xem/xuất leaderboard & ranking'),
                    ),
                    SwitchListTile(
                      value: rolesManage,
                      onChanged: (v) => setStateDialog(() => rolesManage = v),
                      title: const Text('roles_manage'),
                      subtitle: const Text('Quản lý roles (CRUD)'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    final payload = <String, dynamic>{
      'label': labelCtrl.text.trim(),
      'permissions': {
        'admin_access': adminAccess,
        'users_manage': usersManage,
        'posts_manage': postsManage,
        'exercises_manage': exercisesManage,
        'ranking_manage': rankingManage,
        'roles_manage': rolesManage,
      },
    };

    try {
      if (isNew) {
        await widget.api.postJson('/api/admin/roles', {
          'key': keyCtrl.text.trim(),
          ...payload,
        });
        await _load();
        if (mounted) {
          widget.onAfterRoleCreated?.call();
        }
      } else {
        await widget.api.putJson('/api/admin/roles/${role['id']}', payload);
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _deleteRole(Map<String, dynamic> role) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete role?'),
        content: Text(
          'Role: ${role['key']}\n\nAccounts using this role will be reassigned to Student (user) so they can still sign in.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await widget.api.deleteJson('/api/admin/roles/${role['id']}');
      await _load();
      if (!mounted) return;
      final n = res['reassigned_users'];
      if (n is num && n > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role deleted. ${n.toInt()} user(s) reassigned to Student (user).')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final compact = FitnetBreakpoints.isCompactWidth(c.maxWidth);
        final pad = FitnetBreakpoints.pagePaddingInsets(c.maxWidth);

        Widget header() {
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Role Management', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _loading ? null : () => _editRole(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Role'),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: Text('Role Management', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
              FilledButton.icon(
                onPressed: _loading ? null : () => _editRole(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Role'),
              ),
            ],
          );
        }

        Widget errorCard() {
          if (compact) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Text(_error!)),
                  const SizedBox(width: 10),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: pad,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              header(),
              const SizedBox(height: 14),
              if (!_loading && _schemaHint != null)
                Card(
                  color: const Color(0xFFFEF9C3),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF854D0E)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _schemaHint!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF854D0E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_loading && _schemaHint != null) const SizedBox(height: 12),
              if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              if (!_loading && _error != null) errorCard(),
              if (!_loading && _error == null)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (final r in _roles) ...[
                          ListTile(
                            contentPadding: compact ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4) : null,
                            leading: const Icon(Icons.badge_outlined),
                            title: Text('${r['label']}'),
                            subtitle: Text('key: ${r['key']}', maxLines: 2, overflow: TextOverflow.ellipsis),
                            isThreeLine: false,
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _editRole(role: r);
                                if (v == 'delete') _deleteRole(r);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

