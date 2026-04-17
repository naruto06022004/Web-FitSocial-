import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../auth/auth_repository.dart';
import '../models/fitnet_user.dart';
import 'admin_posts_screen.dart';
import 'admin_roles_screen.dart';
import 'admin_users_screen.dart';

enum _AdminPanelKind {
  dashboard,
  users,
  reports,
  posts,
  roles;

  String? get permissionKey => switch (this) {
        users => 'users_manage',
        posts => 'posts_manage',
        roles => 'roles_manage',
        _ => null,
      };

  String get label => switch (this) {
        dashboard => 'Dashboard',
        users => 'User Management',
        reports => 'Reports',
        posts => 'Posts',
        roles => 'Roles',
      };

  IconData get icon => switch (this) {
        dashboard => Icons.dashboard_outlined,
        users => Icons.people_alt_outlined,
        reports => Icons.bar_chart_outlined,
        posts => Icons.article_outlined,
        roles => Icons.admin_panel_settings_outlined,
      };

  IconData get selectedIcon => switch (this) {
        dashboard => Icons.dashboard,
        users => Icons.people_alt,
        reports => Icons.bar_chart,
        posts => Icons.article,
        roles => Icons.admin_panel_settings,
      };
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.api,
    required this.authRepository,
    required this.me,
    required this.onLoggedOut,
    required this.onOpenUserMode,
  });

  final ApiClient api;
  final AuthRepository authRepository;
  final FitnetUser me;
  final VoidCallback onLoggedOut;
  final VoidCallback onOpenUserMode;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late _AdminPanelKind _selected;

  static const _bg = Color(0xFFF8FAFC);
  static const _sidebarBg = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _selected = _firstVisiblePanel(widget.me);
  }

  static _AdminPanelKind _firstVisiblePanel(FitnetUser me) {
    for (final p in _AdminPanelKind.values) {
      if (me.hasPermission(p.permissionKey)) {
        return p;
      }
    }
    return _AdminPanelKind.dashboard;
  }

  List<_AdminPanelKind> _visiblePanels() {
    return _AdminPanelKind.values.where((p) => widget.me.hasPermission(p.permissionKey)).toList();
  }

  Future<void> _logout() async {
    await widget.authRepository.logout();
    widget.onLoggedOut();
  }

  void _openUserMode() => widget.onOpenUserMode();

  void _selectPanel(_AdminPanelKind p) => setState(() => _selected = p);

  Widget _pageForPanel(_AdminPanelKind p) {
    switch (p) {
      case _AdminPanelKind.dashboard:
        return _AdminDashboardHome(
          onOpenUsers: widget.me.hasPermission('users_manage') ? () => _selectPanel(_AdminPanelKind.users) : null,
          onOpenPosts: widget.me.hasPermission('posts_manage') ? () => _selectPanel(_AdminPanelKind.posts) : null,
        );
      case _AdminPanelKind.users:
        return AdminUsersScreen(api: widget.api);
      case _AdminPanelKind.reports:
        return const _Placeholder(title: 'Reports', subtitle: 'Báo cáo sẽ có sau.');
      case _AdminPanelKind.posts:
        return AdminPostsScreen(api: widget.api);
      case _AdminPanelKind.roles:
        return AdminRolesScreen(
          api: widget.api,
          onAfterRoleCreated: widget.me.hasPermission('users_manage')
              ? () {
                  _selectPanel(_AdminPanelKind.users);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Role created. Use User Management → Edit role on each user to assign the new role.'),
                      ),
                    );
                  });
                }
              : null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final panels = _visiblePanels();
    final active = panels.contains(_selected)
        ? _selected
        : (panels.isNotEmpty ? panels.first : _AdminPanelKind.dashboard);
    if (active != _selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selected = active);
      });
    }
    final title = active.label;
    final page = _pageForPanel(active);

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 980;

        if (!wide) {
          return Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              title: Text(title),
              actions: [
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            drawer: Drawer(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: _SidebarHeader(me: widget.me),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 6, 16, 8),
                      child: Text('ADMINISTRATION', style: TextStyle(fontSize: 11, letterSpacing: 0.8, color: Color(0xFF64748B))),
                    ),
                    for (final p in panels)
                      ListTile(
                        selected: active == p,
                        leading: Icon(active == p ? p.selectedIcon : p.icon),
                        title: Text(p.label),
                        onTap: () {
                          Navigator.of(context).pop();
                          _selectPanel(p);
                        },
                      ),
                  ],
                ),
              ),
            ),
            body: page,
          );
        }

        return Scaffold(
          backgroundColor: _bg,
          body: Row(
            children: [
              Container(
                width: 248,
                decoration: BoxDecoration(
                  color: _sidebarBg,
                  border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SidebarHeader(me: widget.me),
                        const SizedBox(height: 14),
                        const Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 8),
                          child: Text('ADMINISTRATION', style: TextStyle(fontSize: 11, letterSpacing: 0.8, color: Color(0xFF64748B))),
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              for (final p in panels)
                                _SidebarItem(
                                  label: p.label,
                                  icon: p.icon,
                                  selectedIcon: p.selectedIcon,
                                  selected: active == p,
                                  onTap: () => _selectPanel(p),
                                ),
                              const SizedBox(height: 6),
                              _SidebarItem(
                                label: 'User UI',
                                icon: Icons.person_outline,
                                selectedIcon: Icons.person,
                                selected: false,
                                onTap: _openUserMode,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F172A),
                            side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SafeArea(
                        bottom: false,
                        child: page,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.me});

  final FitnetUser me;

  String _initials() {
    final n = me.name.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
    }
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final display = me.roleLabel?.trim().isNotEmpty == true ? me.roleLabel! : me.name;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
          foregroundColor: const Color(0xFF2563EB),
          child: Text(_initials(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            display,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? const Color(0xFF0F172A) : const Color(0xFF475569);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? const Color(0xFFE0F2FE) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(selected ? selectedIcon : icon, size: 20, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: fg, fontWeight: selected ? FontWeight.w700 : FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardHome extends StatelessWidget {
  const _AdminDashboardHome({
    this.onOpenUsers,
    this.onOpenPosts,
  });

  final VoidCallback? onOpenUsers;
  final VoidCallback? onOpenPosts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget quickCard({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    }

    final children = <Widget>[
      Text('Dashboard', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text(
        'Tabs follow Role permissions (users_manage, posts_manage, roles_manage).',
        style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
      ),
      const SizedBox(height: 16),
    ];

    if (onOpenUsers != null) {
      children.addAll([
        quickCard(
          icon: Icons.people_alt_outlined,
          title: 'Quản lý theo User (Portfolio)',
          subtitle: 'Mở danh sách user → xem Portfolio & thông tin quản lý',
          onTap: onOpenUsers!,
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (onOpenPosts != null) {
      children.addAll([
        quickCard(
          icon: Icons.article_outlined,
          title: 'Quản lý Posts',
          subtitle: 'Duyệt, lọc, chỉnh sửa và xoá bài viết',
          onTap: onOpenPosts!,
        ),
        const SizedBox(height: 12),
      ]);
    }

    if (onOpenUsers == null && onOpenPosts == null) {
      children.add(
        Text(
          'Bạn không có quyền Users hoặc Posts. Liên hệ Admin để cấp users_manage / posts_manage trong Role.',
          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: children,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B))),
      ],
    );
  }
}
