import 'package:flutter/material.dart';

import '../models/fitnet_user.dart';
import 'fitnet_layout.dart';

typedef FitnetHeaderMessengerTap = void Function();
typedef FitnetHeaderNotificationsTap = void Function();
typedef FitnetHeaderProfileTap = void Function();
typedef FitnetHeaderTabSelected = void Function(int index);
typedef FitnetHeaderSearchSubmitted = void Function(String query);

class FitnetHeader extends StatelessWidget implements PreferredSizeWidget {
  const FitnetHeader({
    super.key,
    required this.me,
    required this.selectedTabIndex,
    required this.hasNotifications,
    required this.searchController,
    required this.onTabSelected,
    required this.onSearchSubmitted,
    required this.onMessenger,
    required this.onNotifications,
    required this.onProfile,
    this.onOpenAdminDashboard,
  });

  final FitnetUser me;
  /// Tab đang chọn (0 Home, 1 Bạn bè, 2 Market). Dùng **-1** nếu không highlight tab (màn phụ).
  final int selectedTabIndex;
  final bool hasNotifications;
  final TextEditingController searchController;

  final FitnetHeaderTabSelected onTabSelected;
  final FitnetHeaderSearchSubmitted onSearchSubmitted;
  final FitnetHeaderMessengerTap onMessenger;
  final FitnetHeaderNotificationsTap onNotifications;
  final FitnetHeaderProfileTap onProfile;
  final VoidCallback? onOpenAdminDashboard;

  static const Color navSelected = Color(0xFF1877F2);

  @override
  Size get preferredSize {
    // NOTE: actual height depends on width (see build()).
    return const Size.fromHeight(120);
  }

  Widget _centerNavButton({
    required IconData iconSelected,
    required IconData iconOutline,
    required String label,
    required int index,
    required bool compact,
  }) {
    final selected = selectedTabIndex >= 0 && selectedTabIndex == index;
    final color = selected ? navSelected : Colors.black54;
    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? iconSelected : iconOutline,
                size: compact ? 22 : 24,
                color: color,
              ),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                if (selected)
                  Container(
                    height: 3,
                    width: 48,
                    decoration: BoxDecoration(
                      color: navSelected,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const SizedBox(height: 3),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _navRow({required bool compact}) {
    return Row(
      children: [
        _centerNavButton(
          index: 0,
          label: 'Home',
          iconSelected: Icons.home,
          iconOutline: Icons.home_outlined,
          compact: compact,
        ),
        _centerNavButton(
          index: 1,
          label: 'Bạn bè',
          iconSelected: Icons.people,
          iconOutline: Icons.people_outline,
          compact: compact,
        ),
        _centerNavButton(
          index: 2,
          label: 'Market',
          iconSelected: Icons.storefront,
          iconOutline: Icons.storefront_outlined,
          compact: compact,
        ),
      ],
    );
  }

  Widget _searchField() {
    return Material(
      color: const Color(0xFFF0F2F5),
      borderRadius: BorderRadius.circular(999),
      child: TextField(
        controller: searchController,
        onSubmitted: onSearchSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm trên Fitnet',
          prefixIcon: const Icon(Icons.search, size: 22, color: Colors.black54),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    searchController.clear();
                    // Caller should rebuild if needed (usually via setState).
                  },
                )
              : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final useGridHeader = width >= 1000;
    final compactNav = width < 520;

    final brand = Text(
      'Fitnet',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: navSelected,
      ),
    );

    final narrowTrailing = Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onOpenAdminDashboard != null)
            IconButton(
              tooltip: 'Admin Dashboard',
              onPressed: onOpenAdminDashboard,
              icon: Icon(Icons.admin_panel_settings_outlined, size: 26, color: Colors.grey.shade800),
            ),
          IconButton(
            tooltip: 'Messenger',
            onPressed: onMessenger,
            icon: Icon(Icons.chat_bubble_outline, size: 26, color: Colors.grey.shade800),
          ),
          IconButton(
            tooltip: 'Thông báo',
            onPressed: onNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, size: 26, color: Colors.grey.shade800),
                if (hasNotifications)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.only(right: 10, left: 4),
              child: CircleAvatar(
                radius: 18,
                child: Text(
                  (me.name.isNotEmpty ? me.name[0] : '?').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Widget wideTitleGrid() {
      return SizedBox(
        height: 72,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: FitnetLayout.maxContentWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                FitnetLayout.pagePadding.left,
                0,
                FitnetLayout.pagePadding.right,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: FitnetLayout.leftRailWidth,
                    child: Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: brand,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: SizedBox(height: 40, child: _searchField())),
                      ],
                    ),
                  ),
                  const SizedBox(width: FitnetLayout.columnGap),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.center,
                      child: _navRow(compact: compactNav),
                    ),
                  ),
                  const SizedBox(width: FitnetLayout.columnGap),
                  SizedBox(
                    width: FitnetLayout.rightRailWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onOpenAdminDashboard != null)
                          IconButton(
                            tooltip: 'Admin Dashboard',
                            onPressed: onOpenAdminDashboard,
                            icon: Icon(Icons.admin_panel_settings_outlined, size: 26, color: Colors.grey.shade800),
                          ),
                        IconButton(
                          tooltip: 'Messenger',
                          onPressed: onMessenger,
                          icon: Icon(Icons.chat_bubble_outline, size: 26, color: Colors.grey.shade800),
                        ),
                        IconButton(
                          tooltip: 'Thông báo',
                          onPressed: onNotifications,
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(Icons.notifications_outlined, size: 26, color: Colors.grey.shade800),
                              if (hasNotifications)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: onProfile,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: CircleAvatar(
                              radius: 18,
                              child: Text(
                                (me.name.isNotEmpty ? me.name[0] : '?').toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final toolbarHeight = useGridHeader ? 72.0 : 120.0;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      titleSpacing: 0,
      toolbarHeight: toolbarHeight,
      title: useGridHeader
          ? wideTitleGrid()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Padding(padding: const EdgeInsets.only(left: 8), child: brand),
                    const SizedBox(width: 8),
                    Expanded(child: SizedBox(height: 40, child: _searchField())),
                    narrowTrailing,
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(height: 56, child: _navRow(compact: compactNav)),
              ],
            ),
    );
  }
}

