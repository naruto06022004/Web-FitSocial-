import 'package:flutter/material.dart';

import '../models/fitnet_user.dart';

class FitnetMobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FitnetMobileTopBar({
    super.key,
    required this.me,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.hasNotifications,
    required this.onMessenger,
    required this.onNotifications,
    required this.onProfile,
    this.onOpenAdminDashboard,
  });

  final FitnetUser me;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final bool hasNotifications;
  final VoidCallback onMessenger;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback? onOpenAdminDashboard;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      titleSpacing: 12,
      title: Row(
        children: [
          Text(
            'Fitnet',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: TextField(
                controller: searchController,
                onSubmitted: onSearchSubmitted,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (onOpenAdminDashboard != null)
          IconButton(
            tooltip: 'Admin Dashboard',
            onPressed: onOpenAdminDashboard,
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
        IconButton(
          tooltip: 'Messenger',
          onPressed: onMessenger,
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: onNotifications,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined),
              if (hasNotifications)
                const Positioned(
                  right: -1,
                  top: -1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: SizedBox(width: 9, height: 9),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(999),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              foregroundColor: theme.colorScheme.primary,
              child: Text(
                (me.name.isNotEmpty ? me.name[0] : '?').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

