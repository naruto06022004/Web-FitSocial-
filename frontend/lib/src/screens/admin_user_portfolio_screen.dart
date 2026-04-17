import 'package:flutter/material.dart';

import '../api/api_client.dart';

class AdminUserPortfolioScreen extends StatefulWidget {
  const AdminUserPortfolioScreen({
    super.key,
    required this.api,
    required this.user,
  });

  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  State<AdminUserPortfolioScreen> createState() => _AdminUserPortfolioScreenState();
}

class _AdminUserPortfolioScreenState extends State<AdminUserPortfolioScreen> {
  late Map<String, dynamic> _user = Map<String, dynamic>.from(widget.user);
  bool _loading = false;

  String get _id => (_user['id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final id = _id;
    if (id.isEmpty) return;
    setState(() => _loading = true);
    try {
      final json = await widget.api.getJson('/api/admin/users/$id');
      final data = json['data'];
      if (data is Map) {
        setState(() => _user = data.cast<String, dynamic>());
      }
    } catch (_) {
      // ignore; keep current snapshot
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update(Map<String, dynamic> patch) async {
    final id = _id;
    if (id.isEmpty) return;
    setState(() => _loading = true);
    try {
      final json = await widget.api.putJson('/api/admin/users/$id', patch);
      final data = json['data'];
      if (data is Map) {
        setState(() => _user = data.cast<String, dynamic>());
      } else {
        await _reload();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lưu thất bại: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editAvatarUrl() async {
    final ctrl = TextEditingController(text: (_user['avatar_url'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi avatar (URL)'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Avatar URL',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      await _update({'avatar_url': ctrl.text.trim()});
    }
  }

  Future<void> _editPersonalInfo() async {
    final bioCtrl = TextEditingController(text: (_user['bio'] ?? '').toString());
    final gymCtrl = TextEditingController(text: (_user['gym_name'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa thông tin cá nhân'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bioCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gymCtrl,
                decoration: const InputDecoration(labelText: 'Gym name', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      await _update({'bio': bioCtrl.text.trim(), 'gym_name': gymCtrl.text.trim()});
    }
  }

  Future<void> _resetPassword() async {
    final passCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cập nhật')),
        ],
      ),
    );
    if (ok == true && passCtrl.text.trim().isNotEmpty) {
      await _update({'password': passCtrl.text});
    }
  }

  Future<void> _changeRole() async {
    String role = (_user['role'] ?? 'user').toString();
    List<Map<String, dynamic>> roles = const [];
    try {
      final json = await widget.api.getJson('/api/admin/roles');
      final data = json['data'];
      roles = (data is List) ? data.cast<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
    } catch (_) {
      // fallback to default static list below
    }
    if (roles.isEmpty) {
      roles = const [
        {'key': 'user', 'label': 'Student'},
        {'key': 'staff', 'label': 'Teacher'},
        {'key': 'admin', 'label': 'Admin'},
      ];
    }

    final roleKeys = roles.map((e) => (e['key'] ?? '').toString()).where((s) => s.isNotEmpty).toSet();
    if (!roleKeys.contains(role)) {
      role = roleKeys.contains('user') ? 'user' : roleKeys.first;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Phân quyền (Role)'),
              content: DropdownButtonFormField<String>(
                key: ValueKey('role_$role'),
                initialValue: role,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Role'),
                items: [
                  for (final r in roles)
                    DropdownMenuItem(
                      value: (r['key'] ?? '').toString(),
                      child: Text('${r['label'] ?? r['key']}'),
                    ),
                ],
                onChanged: (v) => setStateDialog(() => role = v ?? 'user'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
              ],
            );
          },
        );
      },
    );
    if (ok == true) {
      await _update({'role': role});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (_user['name'] ?? '').toString();
    final email = (_user['email'] ?? '').toString();
    final role = (_user['role'] ?? '').toString();
    final roleLabelRaw = _user['role_label']?.toString().trim();
    final roleDisplay = (roleLabelRaw != null && roleLabelRaw.isNotEmpty)
        ? (roleLabelRaw.toLowerCase() == role.toLowerCase() ? roleLabelRaw : '$roleLabelRaw ($role)')
        : role;
    final status = (_user['status'] ?? 'Active').toString();
    final id = (_user['id'] ?? '').toString();
    final avatarUrl = (_user['avatar_url'] ?? _user['avatar'] ?? '').toString();
    final bio = (_user['bio'] ?? '').toString();
    final gymName = (_user['gym_name'] ?? _user['gymName'] ?? '').toString();

    final friendsCount = int.tryParse((_user['friends_count'] ?? _user['friendsCount'] ?? '').toString()) ?? 0;
    final postsCount = int.tryParse((_user['posts_count'] ?? _user['postsCount'] ?? '').toString()) ?? 0;
    final photosRaw = _user['photos'] ?? _user['images'] ?? _user['media'];
    final photos = (photosRaw is List) ? photosRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() : <String>[];

    Widget infoRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B), fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    Widget sectionTitle(String t) => Text(t, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900));

    Widget statChip({required IconData icon, required String label, required String value}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    Widget managementActions() {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: _loading ? null : _changeRole,
            icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
            label: const Text('Phân quyền (Role)'),
          ),
          FilledButton.tonalIcon(
            onPressed: _loading ? null : _editAvatarUrl,
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: const Text('Đổi avatar'),
          ),
          OutlinedButton.icon(
            onPressed: _loading ? null : _editPersonalInfo,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Sửa thông tin'),
          ),
          OutlinedButton.icon(
            onPressed: _loading ? null : _resetPassword,
            icon: const Icon(Icons.key_outlined, size: 18),
            label: const Text('Reset password'),
          ),
        ],
      );
    }

    Widget personalInfoCard() {
      Widget row(IconData icon, String text) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF475569)),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            ],
          ),
        );
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: sectionTitle('Thông tin cá nhân')),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit info (demo)'))),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              row(Icons.info_outline, bio.isEmpty ? 'Chưa có bio' : bio),
              row(Icons.fitness_center, gymName.isEmpty ? 'Chưa có gym' : gymName),
              const Divider(height: 24),
              row(Icons.email_outlined, email.isEmpty ? '-' : email),
              row(Icons.badge_outlined, 'Vai trò: ${role.isEmpty ? '-' : roleDisplay}'),
            ],
          ),
        ),
      );
    }

    Widget photosGridCard() {
      Widget tile({required Widget child}) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: child,
            ),
          ),
        );
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: sectionTitle('Ảnh user đăng')),
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xem tất cả ảnh (demo)'))),
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (photos.isEmpty)
                tile(
                  child: Center(
                    child: Text(
                      'Chưa có ảnh',
                      style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B), fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth >= 900 ? 5 : c.maxWidth >= 700 ? 4 : 3;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: photos.length.clamp(0, 12),
                      itemBuilder: (context, i) {
                        final url = photos[i];
                        return tile(
                          child: InkWell(
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mở ảnh (demo)'))),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, st) {
                                return const Center(child: Icon(Icons.image_not_supported_outlined));
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Portfolio — ${name.isEmpty ? 'User' : name}'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _loading ? null : _reload,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                foregroundColor: theme.colorScheme.primary,
                backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
                child: avatarUrl.isEmpty
                    ? Text((name.isNotEmpty ? name[0] : '?').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? 'User' : name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(email, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B))),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        statChip(icon: Icons.people_alt_outlined, label: 'bạn bè', value: friendsCount.toString()),
                        statChip(icon: Icons.article_outlined, label: 'posts', value: postsCount.toString()),
                        statChip(icon: Icons.photo_library_outlined, label: 'ảnh', value: photos.length.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle('Thông tin quản lý'),
                  const SizedBox(height: 10),
                  infoRow('User ID', id),
                  infoRow('Role', roleDisplay),
                  infoRow('Status', status),
                  infoRow('Last login', (_user['last_login'] ?? _user['last_login_at'] ?? '').toString()),
                  const SizedBox(height: 10),
                  managementActions(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle('Quyền theo Role'),
                  const SizedBox(height: 10),
                  Text(
                    role == 'admin'
                        ? 'Admin: toàn quyền (Users/Posts/Settings).'
                        : role == 'staff'
                            ? 'Teacher: truy cập dashboard, quản lý posts; giới hạn một số thao tác user.'
                            : role == 'user'
                                ? 'Student: chỉ dùng giao diện người dùng.'
                                : 'Vai trò tùy chỉnh ($role). Quyền cụ thể nằm trong Role Management.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          personalInfoCard(),
          const SizedBox(height: 12),
          photosGridCard(),
        ],
      ),
    );
  }
}

