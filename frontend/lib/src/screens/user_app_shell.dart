import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../auth/auth_repository.dart';
import '../models/fitnet_user.dart';
import '../ui/fitnet_layout.dart';
import 'friends_screen.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'profile_screen.dart';

class UserAppShell extends StatefulWidget {
  const UserAppShell({
    super.key,
    required this.api,
    required this.me,
    required this.authRepository,
    required this.onLoggedOut,
  });

  final ApiClient api;
  final FitnetUser me;
  final AuthRepository authRepository;
  final VoidCallback onLoggedOut;

  @override
  State<UserAppShell> createState() => _UserAppShellState();
}

class _UserAppShellState extends State<UserAppShell> {
  int _tabIndex = 0;
  bool _hasNotifications = true;
  final TextEditingController _searchCtrl = TextEditingController();

  static const Color _navSelected = Color(0xFF1877F2);

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

  void _openMessenger() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tin nhắn (demo)')),
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

  Widget _centerNavButton({
    required IconData iconSelected,
    required IconData iconOutline,
    required String label,
    required int index,
    bool compact = false,
  }) {
    final selected = _tabIndex == index;
    final color = selected ? _navSelected : Colors.black54;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 4 : 4),
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
                      color: _navSelected,
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
        controller: _searchCtrl,
        onSubmitted: _submitSearch,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm trên Fitnet',
          prefixIcon: const Icon(Icons.search, size: 22, color: Colors.black54),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    // Cùng ngưỡng với HomeScreen (3 cột feed).
    final useGridHeader = width >= 1000;
    final compactNav = width < 520;

    final brand = Text(
      'Fitnet',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: _navSelected,
      ),
    );

    Widget wideTitleGrid() {
      return SizedBox(
        height: 72,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: FitnetLayout.maxContentWidth),
            child: Padding(
              padding: EdgeInsets.only(
                left: FitnetLayout.pagePadding.left,
                right: FitnetLayout.pagePadding.right,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                SizedBox(
                  width: FitnetLayout.leftRailWidth,
                  child: Row(
                    children: [
                      Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: brand)),
                      const SizedBox(width: 8),
                      Expanded(child: SizedBox(height: 40, child: _searchField())),
                    ],
                  ),
                ),
                SizedBox(width: FitnetLayout.columnGap),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.center,
                    child: _navRow(compact: compactNav),
                  ),
                ),
                SizedBox(width: FitnetLayout.columnGap),
                SizedBox(
                  width: FitnetLayout.rightRailWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Messenger',
                        onPressed: _openMessenger,
                        icon: Icon(Icons.chat_bubble_outline, size: 26, color: Colors.grey.shade800),
                      ),
                      IconButton(
                        tooltip: 'Thông báo',
                        onPressed: _openNotifications,
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.notifications_outlined, size: 26, color: Colors.grey.shade800),
                            if (_hasNotifications)
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
                        onTap: _openProfilePage,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: CircleAvatar(
                            radius: 18,
                            child: Text(
                              (widget.me.name.isNotEmpty ? widget.me.name[0] : '?').toUpperCase(),
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

    final narrowTrailing = Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Messenger',
            onPressed: _openMessenger,
            icon: Icon(Icons.chat_bubble_outline, size: 26, color: Colors.grey.shade800),
          ),
          IconButton(
            tooltip: 'Thông báo',
            onPressed: _openNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, size: 26, color: Colors.grey.shade800),
                if (_hasNotifications)
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
            onTap: _openProfilePage,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.only(right: 10, left: 4),
              child: CircleAvatar(
                radius: 18,
                child: Text(
                  (widget.me.name.isNotEmpty ? widget.me.name[0] : '?').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0.5,
        scrolledUnderElevation: 0.5,
        titleSpacing: 0,
        toolbarHeight: useGridHeader ? 72 : 120,
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
                      Expanded(
                        child: SizedBox(height: 40, child: _searchField()),
                      ),
                      narrowTrailing,
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(height: 56, child: _navRow(compact: compactNav)),
                ],
              ),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          HomeScreen(api: widget.api, me: widget.me),
          FriendsScreen(api: widget.api),
          MarketScreen(api: widget.api),
        ],
      ),
    );
  }
}
