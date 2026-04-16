import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../auth/auth_repository.dart';
import 'admin_posts_screen.dart';
import 'admin_roles_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.api,
    required this.authRepository,
    required this.onLoggedOut,
    required this.onOpenUserMode,
  });

  final ApiClient api;
  final AuthRepository authRepository;
  final VoidCallback onLoggedOut;
  final VoidCallback onOpenUserMode;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;

  static const _bg = Color(0xFFF8FAFC);
  static const _sidebarBg = Color(0xFFF1F5F9);

  Future<void> _logout() async {
    await widget.authRepository.logout();
    widget.onLoggedOut();
  }

  void _openUserMode() => widget.onOpenUserMode();

  void _select(int i) => setState(() => _index = i);

  List<_AdminNavItem> get _items => const [
        _AdminNavItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
        ),
        _AdminNavItem(
          label: 'User Management',
          icon: Icons.people_alt_outlined,
          selectedIcon: Icons.people_alt,
        ),
        _AdminNavItem(
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
        ),
        _AdminNavItem(
          label: 'Posts',
          icon: Icons.article_outlined,
          selectedIcon: Icons.article,
        ),
        _AdminNavItem(
          label: 'Roles',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
        ),
      ];

  Widget _pageForIndex(int i) {
    switch (i) {
      case 0:
        return _AdminDashboardHome(
          onOpenUsers: () => _select(1),
          onOpenPosts: () => _select(3),
        );
      case 1:
        return AdminUsersScreen(api: widget.api);
      case 2:
        return const _Placeholder(title: 'Reports', subtitle: 'Báo cáo sẽ có sau.');
      case 3:
        return AdminPostsScreen(api: widget.api);
      case 4:
        return AdminRolesScreen(api: widget.api);
      default:
        return _AdminDashboardHome(
          onOpenUsers: () => _select(1),
          onOpenPosts: () => _select(3),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final title = items[_index].label;

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 980;
        final page = _pageForIndex(_index);

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
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: _SidebarHeader(),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 6, 16, 8),
                      child: Text('ADMINISTRATION', style: TextStyle(fontSize: 11, letterSpacing: 0.8, color: Color(0xFF64748B))),
                    ),
                    for (var i = 0; i < items.length; i++)
                      ListTile(
                        selected: _index == i,
                        leading: Icon(_index == i ? items[i].selectedIcon : items[i].icon),
                        title: Text(items[i].label),
                        onTap: () {
                          Navigator.of(context).pop();
                          _select(i);
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
                        const _SidebarHeader(),
                        const SizedBox(height: 14),
                        const Padding(
                          padding: EdgeInsets.only(left: 10, bottom: 8),
                          child: Text('ADMINISTRATION', style: TextStyle(fontSize: 11, letterSpacing: 0.8, color: Color(0xFF64748B))),
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              for (var i = 0; i < items.length; i++)
                                _SidebarItem(
                                  label: items[i].label,
                                  icon: items[i].icon,
                                  selectedIcon: items[i].selectedIcon,
                                  selected: _index == i,
                                  onTap: () => _select(i),
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

class _AdminNavItem {
  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
          foregroundColor: const Color(0xFF2563EB),
          child: const Text('SA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'SchoolAdmin',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
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
    required this.onOpenUsers,
    required this.onOpenPosts,
  });

  final VoidCallback onOpenUsers;
  final VoidCallback onOpenPosts;

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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Dashboard', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Quản lý nội dung theo user & bài viết', style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B))),
        const SizedBox(height: 16),
        quickCard(
          icon: Icons.people_alt_outlined,
          title: 'Quản lý theo User (Portfolio)',
          subtitle: 'Mở danh sách user → xem Portfolio & thông tin quản lý',
          onTap: onOpenUsers,
        ),
        const SizedBox(height: 12),
        quickCard(
          icon: Icons.article_outlined,
          title: 'Quản lý Posts',
          subtitle: 'Duyệt, lọc, chỉnh sửa và xoá bài viết',
          onTap: onOpenPosts,
        ),
      ],
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

