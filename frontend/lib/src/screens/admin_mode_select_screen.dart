import 'package:flutter/material.dart';

import '../models/fitnet_user.dart';

class AdminModeSelectScreen extends StatelessWidget {
  const AdminModeSelectScreen({
    super.key,
    required this.user,
    required this.onOpenAdminDashboard,
    required this.onOpenUserMode,
  });

  final FitnetUser user;
  final VoidCallback onOpenAdminDashboard;
  final VoidCallback onOpenUserMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn chế độ'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xin chào, ${user.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Bạn đang đăng nhập bằng tài khoản phân quyền `${user.role}`. Chọn chế độ để tiếp tục.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: onOpenAdminDashboard,
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Dashboard quản lý (Users & Posts)'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.tonalIcon(
                      onPressed: onOpenUserMode,
                      icon: const Icon(Icons.person),
                      label: const Text('Chế độ người dùng (User UI)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

