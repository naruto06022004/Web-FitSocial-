import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../auth/auth_repository.dart';
import '../models/fitnet_user.dart';
import '../ui/fitnet_chrome.dart';
import '../ui/fitnet_header.dart';
import '../ui/fitnet_mobile_top_bar.dart';
import 'chat/chat_conversations_screen.dart';
import 'friends_screen.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'nearby_gyms_screen.dart';
import 'profile_screen.dart';

class UserAppShell extends StatefulWidget {
  const UserAppShell({
    super.key,
    required this.api,
    required this.me,
    required this.authRepository,
    required this.onLoggedOut,
    this.onOpenAdminDashboard,
  });

  final ApiClient api;
  final FitnetUser me;
  final AuthRepository authRepository;
  final VoidCallback onLoggedOut;
  final VoidCallback? onOpenAdminDashboard;

  @override
  State<UserAppShell> createState() => _UserAppShellState();
}

class _UserAppShellState extends State<UserAppShell> {
  int _tabIndex = 0;
  bool _hasNotifications = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await widget.authRepository.logout();
    widget.onLoggedOut();
  }

  void _submitSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tìm kiếm: $q (demo)')),
    );
  }

  /// Cùng header với Home cho mọi màn push (chat, phòng gym, …).
  Widget _fitnetChromePage(BuildContext routeContext, Widget body) {
    return FitnetChrome(
      me: widget.me,
      selectedTabIndex: -1,
      hasNotifications: _hasNotifications,
      searchController: _searchCtrl,
      onTabSelected: (i) {
        Navigator.of(routeContext).popUntil((r) => r.isFirst);
        setState(() => _tabIndex = i);
      },
      onSearchSubmitted: _submitSearch,
      onMessenger: () {
        final nav = Navigator.of(routeContext);
        if (nav.canPop()) {
          nav.maybePop();
        }
      },
      onNotifications: () {
        Navigator.of(routeContext).popUntil((r) => r.isFirst);
        _openNotifications();
      },
      onProfile: () {
        Navigator.of(routeContext).popUntil((r) => r.isFirst);
        _openProfilePage();
      },
      body: body,
      onOpenAdminDashboard: widget.onOpenAdminDashboard,
    );
  }

  void _pushFitnetPage(BuildContext navigatorContext, Widget page) {
    Navigator.of(navigatorContext).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => _fitnetChromePage(routeContext, page),
      ),
    );
  }

  void _replaceFitnetPage(BuildContext navigatorContext, Widget page) {
    Navigator.of(navigatorContext).pushReplacement(
      MaterialPageRoute<void>(
        builder: (routeContext) => _fitnetChromePage(routeContext, page),
      ),
    );
  }

  void _openMessenger() {
    _pushFitnetPage(
      context,
      ChatConversationsScreen(
        api: widget.api,
        me: widget.me,
        pushChrome: _pushFitnetPage,
        replaceChrome: _replaceFitnetPage,
      ),
    );
  }

  void _openNearbyGyms() {
    _pushFitnetPage(
      context,
      NearbyGymsScreen(api: widget.api),
    );
  }

  void _openNotifications() {
    setState(() => _hasNotifications = false);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: const [
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Thông báo (demo)'),
              subtitle: Text('Hiện chưa có API thông báo.'),
            ),
          ],
        );
      },
    );
  }

  void _openProfilePage() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => ProfileScreen(
          api: widget.api,
          me: widget.me,
          authRepository: widget.authRepository,
          onLoggedOut: () {
            Navigator.of(ctx).popUntil((route) => route.isFirst);
            _logout();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;

    final pages = [
      HomeScreen(
        api: widget.api,
        me: widget.me,
        onOpenNearbyGyms: _openNearbyGyms,
      ),
      FriendsScreen(api: widget.api),
      MarketScreen(api: widget.api),
    ];

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: FitnetMobileTopBar(
          me: widget.me,
          searchController: _searchCtrl,
          onSearchSubmitted: _submitSearch,
          hasNotifications: _hasNotifications,
          onMessenger: _openMessenger,
          onNotifications: _openNotifications,
          onProfile: _openProfilePage,
          onOpenAdminDashboard: widget.onOpenAdminDashboard,
        ),
        body: IndexedStack(index: _tabIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (i) => setState(() => _tabIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Bạn bè'),
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Market'),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: FitnetHeader(
        me: widget.me,
        selectedTabIndex: _tabIndex,
        hasNotifications: _hasNotifications,
        searchController: _searchCtrl,
        onTabSelected: (i) => setState(() => _tabIndex = i),
        onSearchSubmitted: _submitSearch,
        onMessenger: _openMessenger,
        onNotifications: _openNotifications,
        onProfile: _openProfilePage,
        onOpenAdminDashboard: widget.onOpenAdminDashboard,
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: pages,
      ),
    );
  }
}
