import 'package:flutter/material.dart';

import '../models/fitnet_user.dart';
import 'fitnet_header.dart';

/// Scaffold có cùng [FitnetHeader] như trang Home (dùng cho màn push: chat, phòng gym, …).
class FitnetChrome extends StatelessWidget {
  const FitnetChrome({
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
    required this.body,
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.onOpenAdminDashboard,
  });

  final FitnetUser me;
  final int? selectedTabIndex;
  final bool hasNotifications;
  final TextEditingController searchController;
  final FitnetHeaderTabSelected onTabSelected;
  final FitnetHeaderSearchSubmitted onSearchSubmitted;
  final FitnetHeaderMessengerTap onMessenger;
  final FitnetHeaderNotificationsTap onNotifications;
  final FitnetHeaderProfileTap onProfile;
  final Widget body;
  final Color backgroundColor;
  final VoidCallback? onOpenAdminDashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: FitnetHeader(
        me: me,
        selectedTabIndex: selectedTabIndex ?? -1,
        hasNotifications: hasNotifications,
        searchController: searchController,
        onTabSelected: onTabSelected,
        onSearchSubmitted: onSearchSubmitted,
        onMessenger: onMessenger,
        onNotifications: onNotifications,
        onProfile: onProfile,
        onOpenAdminDashboard: onOpenAdminDashboard,
      ),
      body: body,
    );
  }
}
