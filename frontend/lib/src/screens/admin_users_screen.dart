import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../ui/fitnet_layout.dart';
import 'admin_user_portfolio_screen.dart';

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
  List<Map<String, dynamic>> _roleOptions = const [];

  final _searchCtrl = TextEditingController();
  String _roleFilter = 'all';
  String _statusFilter = 'All Status';

  static String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Teacher';
      case 'user':
      default:
        return 'Student';
    }
  }

  /// Prefer API [role_label] (from Role Management); fallback for legacy keys.
  static String displayRoleForUser(Map<String, dynamic> u) {
    final rl = u['role_label']?.toString().trim();
    if (rl != null && rl.isNotEmpty) return rl;
    return _roleLabel((u['role'] ?? 'user').toString());
  }

  List<Map<String, String>> _roleFilterRows() {
    if (_roleOptions.isNotEmpty) {
      final sorted = List<Map<String, dynamic>>.from(_roleOptions);
      sorted.sort((a, b) => (a['key'] ?? '').toString().compareTo((b['key'] ?? '').toString()));
      return [
        {'value': 'all', 'label': 'All Roles'},
        for (final r in sorted)
          {
            'value': (r['key'] ?? '').toString(),
            'label': (r['label'] ?? r['key']).toString(),
          },
      ];
    }
    return [
      {'value': 'all', 'label': 'All Roles'},
      {'value': 'staff', 'label': 'Teacher'},
      {'value': 'user', 'label': 'Student'},
      {'value': 'admin', 'label': 'Admin'},
    ];
  }

  List<DropdownMenuItem<String>> _rolePickItems({String? ensureKey}) {
    final seen = <String>{};
    final out = <DropdownMenuItem<String>>[];

    void add(String k, String label) {
      if (k.isEmpty || seen.contains(k)) return;
      seen.add(k);
      out.add(DropdownMenuItem<String>(value: k, child: Text(label)));
    }

    for (final r in _roleOptions) {
      final k = (r['key'] ?? '').toString();
      final lab = (r['label'] ?? k).toString();
      add(k, '$lab ($k)');
    }
    final ek = ensureKey?.trim() ?? '';
    if (ek.isNotEmpty && !seen.contains(ek)) {
      add(ek, '${_roleLabel(ek)} ($ek)');
    }
    if (out.isEmpty) {
      add('user', 'Student (user)');
      add('staff', 'Teacher (staff)');
      add('admin', 'Admin (admin)');
    }
    return out;
  }

  String _defaultNewUserRole() {
    if (_roleOptions.any((r) => (r['key'] ?? '').toString() == 'user')) return 'user';
    if (_roleOptions.isNotEmpty) return (_roleOptions.first['key'] ?? 'user').toString();
    return 'user';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      List<Map<String, dynamic>> opts = const [];
      final meta = json['meta'];
      if (meta is Map) {
        final ro = meta['role_options'];
        if (ro is List) {
          opts = ro.cast<Map>().map((e) => e.cast<String, dynamic>()).toList();
        }
      }
      setState(() {
        _items = list;
        _roleOptions = opts;
        final allowed = _roleFilterRows().map((e) => e['value']).toSet();
        if (!allowed.contains(_roleFilter)) {
          _roleFilter = 'all';
        }
      });
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
    String role = _defaultNewUserRole();
    String status = 'Active';
    final roleItems = _rolePickItems();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            InputDecoration deco(String label, {String? hint}) => InputDecoration(
                  labelText: label,
                  hintText: hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                );

            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Row(
                children: [
                  const Expanded(child: Text('Add New User')),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(controller: nameCtrl, decoration: deco('Full Name*', hint: 'Enter full name')),
                      const SizedBox(height: 10),
                      TextField(controller: emailCtrl, decoration: deco('Email Address*', hint: 'Enter email address')),
                      const SizedBox(height: 10),
                      TextField(
                        controller: passwordCtrl,
                        decoration: deco('Password*', hint: 'Enter password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        key: ValueKey('role_$role'),
                        initialValue: roleItems.any((i) => i.value == role) ? role : roleItems.first.value,
                        decoration: deco('Role*', hint: 'Select role'),
                        items: roleItems,
                        onChanged: (v) => setStateDialog(() => role = v ?? roleItems.first.value!),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        key: ValueKey('status_$status'),
                        initialValue: status,
                        decoration: deco('Status', hint: 'Select status'),
                        items: const [
                          DropdownMenuItem(value: 'Active', child: Text('Active')),
                          DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                        ],
                        onChanged: (v) => setStateDialog(() => status = v ?? 'Active'),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Status chỉ dùng để hiển thị (demo) nếu API chưa hỗ trợ.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                  child: const Text('Add User'),
                ),
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
    final pickItems = _rolePickItems(ensureKey: currentRole);
    if (!pickItems.any((i) => i.value == nextRole)) {
      nextRole = pickItems.first.value!;
    }

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
                    value: pickItems.any((i) => i.value == nextRole) ? nextRole : pickItems.first.value,
                    items: pickItems,
                    onChanged: (v) => setStateDialog(() => nextRole = v ?? pickItems.first.value!),
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

  void _openPortfolio(Map<String, dynamic> u) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminUserPortfolioScreen(api: widget.api, user: u),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final useCards = FitnetBreakpoints.useAdminCards(screenW);
    final compactHeader = FitnetBreakpoints.isCompactWidth(screenW);
    final q = _searchCtrl.text.trim().toLowerCase();

    final filtered = _items.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? 'user').toString();
      final status = (u['status'] ?? 'Active').toString();

      if (q.isNotEmpty && !(name.contains(q) || email.contains(q))) return false;
      if (_roleFilter != 'all' && role.toLowerCase() != _roleFilter.toLowerCase()) return false;
      if (_statusFilter != 'All Status' && status.toLowerCase() != _statusFilter.toLowerCase()) return false;
      return true;
    }).toList();

    Widget pill(String text, {bool active = true}) {
      final bg = active ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
      final fg = active ? Colors.white : const Color(0xFF0F172A);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
      );
    }

    Widget pageHeader() {
      final addBtn = FilledButton.icon(
        onPressed: _loading ? null : _createUser,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add New User'),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
      );

      if (compactHeader) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('User Management', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Manage users in the system',
              style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            addBtn,
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Management', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Manage users in the system',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          addBtn,
        ],
      );
    }

    Widget directoryCard() {
      final roles = _roleFilterRows();
      final statuses = <String>['All Status', 'Active', 'Inactive'];

      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('User Directory', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Search and filter users (${filtered.length} users)',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 720;
                  final search = TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
                    ),
                  );

                  final roleDd = DropdownButtonFormField<String>(
                    key: ValueKey('roleFilter_$_roleFilter'),
                    initialValue: _roleFilter,
                    items: [
                      for (final r in roles) DropdownMenuItem(value: r['value'], child: Text(r['label']!)),
                    ],
                    onChanged: (v) => setState(() => _roleFilter = v ?? 'all'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
                      isDense: true,
                    ),
                  );

                  final statusDd = DropdownButtonFormField<String>(
                    key: ValueKey('statusFilter_$_statusFilter'),
                    initialValue: _statusFilter,
                    items: [for (final s in statuses) DropdownMenuItem(value: s, child: Text(s))],
                    onChanged: (v) => setState(() => _statusFilter = v ?? 'All Status'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
                      isDense: true,
                    ),
                  );

                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        search,
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: roleDd),
                            const SizedBox(width: 10),
                            Expanded(child: statusDd),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 12),
                      SizedBox(width: 160, child: roleDd),
                      const SizedBox(width: 12),
                      SizedBox(width: 160, child: statusDd),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: useCards
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                            const SizedBox(height: 12),
                            FilledButton(onPressed: _load, child: const Text('Thử lại')),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
                            const SizedBox(width: 10),
                            FilledButton(onPressed: _load, child: const Text('Thử lại')),
                          ],
                        ),
                )
              else if (useCards)
                _AdminUsersCardList(
                  theme: theme,
                  users: filtered,
                  pill: pill,
                  onEditRole: _updateRole,
                  onDelete: _deleteUser,
                  onOpenPortfolio: _openPortfolio,
                )
              else
                LayoutBuilder(
                  builder: (context, c) {
                    final maxTableHeight = (MediaQuery.of(context).size.height - 320).clamp(240.0, 620.0);
                    final vertical = ScrollController();

                    return SizedBox(
                      height: maxTableHeight,
                      child: Scrollbar(
                        controller: vertical,
                        thumbVisibility: true,
                        trackVisibility: true,
                        interactive: true,
                        child: SingleChildScrollView(
                          controller: vertical,
                          child: _AdminUsersFlexTable(
                            theme: theme,
                            users: filtered,
                            pill: pill,
                            onEditRole: _updateRole,
                            onDelete: _deleteUser,
                            onOpenPortfolio: _openPortfolio,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: FitnetBreakpoints.pagePaddingInsets(screenW),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          pageHeader(),
          const SizedBox(height: 16),
          directoryCard(),
        ],
      ),
    );
  }
}

class _AdminUsersCardList extends StatelessWidget {
  const _AdminUsersCardList({
    required this.theme,
    required this.users,
    required this.pill,
    required this.onEditRole,
    required this.onDelete,
    required this.onOpenPortfolio,
  });

  final ThemeData theme;
  final List<Map<String, dynamic>> users;
  final Widget Function(String text, {bool active}) pill;
  final Future<void> Function(Map<String, dynamic> u) onEditRole;
  final Future<void> Function(Map<String, dynamic> u) onDelete;
  final void Function(Map<String, dynamic> u) onOpenPortfolio;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Không có user phù hợp bộ lọc',
          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final u in users)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          u['name']?.toString() ?? '(no name)',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      PopupMenuButton<_UserAction>(
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (a) async {
                          if (a == _UserAction.portfolio) {
                            onOpenPortfolio(u);
                          } else if (a == _UserAction.editRole) {
                            await onEditRole(u);
                          } else if (a == _UserAction.delete) {
                            await onDelete(u);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: _UserAction.portfolio, child: Text('Portfolio')),
                          PopupMenuItem(value: _UserAction.editRole, child: Text('Edit role')),
                          PopupMenuItem(value: _UserAction.delete, child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    u['email']?.toString() ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final status = (u['status'] ?? 'Active').toString();
                      final inactive = status.toLowerCase() == 'inactive';
                      final statusW = inactive ? pill('Inactive', active: false) : pill('Active', active: true);
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _AdminUsersScreenState.displayRoleForUser(u),
                            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          statusW,
                          Text(
                            _formatLastLogin(u, now: now),
                            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminUsersFlexTable extends StatelessWidget {
  const _AdminUsersFlexTable({
    required this.theme,
    required this.users,
    required this.pill,
    required this.onEditRole,
    required this.onDelete,
    required this.onOpenPortfolio,
  });

  final ThemeData theme;
  final List<Map<String, dynamic>> users;
  final Widget Function(String text, {bool active}) pill;
  final Future<void> Function(Map<String, dynamic> u) onEditRole;
  final Future<void> Function(Map<String, dynamic> u) onDelete;
  final void Function(Map<String, dynamic> u) onOpenPortfolio;

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: Colors.black.withValues(alpha: 0.06));
    final now = DateTime.now();

    Widget headerCell(String t, int flex) {
      return Expanded(
        flex: flex,
        child: Text(
          t,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: const Color(0xFF475569),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Widget cell(Widget child, int flex, {Alignment align = Alignment.centerLeft}) {
      return Expanded(
        flex: flex,
        child: Align(alignment: align, child: child),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: border, left: border, right: border, bottom: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  headerCell('NAME', 3),
                  const SizedBox(width: 12),
                  headerCell('EMAIL', 4),
                  const SizedBox(width: 12),
                  headerCell('ROLE', 2),
                  const SizedBox(width: 12),
                  headerCell('STATUS', 2),
                  const SizedBox(width: 12),
                  headerCell('LAST LOGIN', 2),
                  const SizedBox(width: 12),
                  headerCell('ACTIONS', 2),
                ],
              ),
            ),
            if (users.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'Không có user phù hợp bộ lọc',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                itemBuilder: (context, i) {
                  final u = users[i];
                  final status = (u['status'] ?? 'Active').toString();
                  final inactive = status.toLowerCase() == 'inactive';
                  final lastLoginText = _formatLastLogin(u, now: now);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        cell(
                          Text(
                            u['name']?.toString() ?? '(no name)',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          3,
                        ),
                        const SizedBox(width: 12),
                        cell(
                          Text(
                            u['email']?.toString() ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF475569)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          4,
                        ),
                        const SizedBox(width: 12),
                        cell(
                          Text(
                            _AdminUsersScreenState.displayRoleForUser(u),
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          2,
                        ),
                        const SizedBox(width: 12),
                        cell(
                          inactive ? pill('Inactive', active: false) : pill('Active', active: true),
                          2,
                        ),
                        const SizedBox(width: 12),
                        cell(
                          Text(
                            lastLoginText,
                            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF475569)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          2,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: PopupMenuButton<_UserAction>(
                              tooltip: 'Actions',
                              icon: const Icon(Icons.more_horiz),
                              onSelected: (a) async {
                                if (a == _UserAction.portfolio) {
                                  onOpenPortfolio(u);
                                } else if (a == _UserAction.editRole) {
                                  await onEditRole(u);
                                } else if (a == _UserAction.delete) {
                                  await onDelete(u);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: _UserAction.portfolio,
                                  child: Text('Portfolio'),
                                ),
                                PopupMenuItem(
                                  value: _UserAction.editRole,
                                  child: Text('Edit role'),
                                ),
                                PopupMenuItem(
                                  value: _UserAction.delete,
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

enum _UserAction { portfolio, editRole, delete }

String _formatLastLogin(Map<String, dynamic> u, {required DateTime now}) {
  final raw = u['last_login'] ?? u['last_login_at'] ?? u['lastLogin'] ?? u['last_login_time'];
  if (raw == null) return '';

  final s = raw.toString().trim();
  if (s.isEmpty) return '';

  final dt = DateTime.tryParse(s);
  if (dt == null) return s; // already "2 hours ago" or unknown format

  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

