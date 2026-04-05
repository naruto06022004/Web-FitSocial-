import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../auth/auth_repository.dart';
import 'admin_posts_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.api,
    required this.authRepository,
    required this.onLoggedOut,
  });

  final ApiClient api;
  final AuthRepository authRepository;
  final VoidCallback onLoggedOut;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;

  Future<void> _logout() async {
    await widget.authRepository.logout();
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AdminPostsScreen(api: widget.api),
      AdminUsersScreen(api: widget.api),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard quản lý'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}

