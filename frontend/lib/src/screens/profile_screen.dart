import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../auth/auth_repository.dart';
import '../debug/debug_log_screen.dart';
import '../models/fitnet_user.dart';
import 'evaluation_screen.dart';

/// Trang cá nhân bố cục giống Facebook: top bar, ảnh bìa, avatar, tab, 2 cột (giới thiệu | bài viết).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
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
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _fbBg = Color(0xFFF0F2F5);

  int _profileSectionTab = 0;
  bool _postsGridView = false;

  Future<void> _logout() async {
    await widget.authRepository.logout();
    widget.onLoggedOut();
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Debug logs'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugLogScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_rate_outlined),
                title: const Text('Đánh giá bài tập'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EvaluationScreen(api: widget.api)));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text('Đăng xuất', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    final initial = (me.name.isNotEmpty ? me.name[0] : '?').toUpperCase();

    return Scaffold(
      backgroundColor: _fbBg,
      body: Column(
        children: [
          _FitnetTopBar(
            initial: initial,
            onBack: () => Navigator.of(context).pop(),
            onOpenMenu: () => _showMoreSheet(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1020),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        _CoverAndIdentity(
                          me: me,
                          initial: initial,
                          friendsCount: 110,
                          onAddCover: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Thêm ảnh bìa (demo)')),
                            );
                          },
                          onAddStory: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Thêm vào tin (demo)')),
                            );
                          },
                          onEditProfile: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chỉnh sửa trang cá nhân (demo)')),
                            );
                          },
                        ),
                        _ProfileSubTabs(
                          selectedIndex: _profileSectionTab,
                          onSelect: (i) => setState(() => _profileSectionTab = i),
                          onMore: () => _showMoreSheet(context),
                        ),
                        const SizedBox(height: 12),
                        if (_profileSectionTab == 0)
                          LayoutBuilder(
                            builder: (context, c) {
                              final wide = c.maxWidth >= 720;
                              if (wide) {
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 5, child: _IntroCard(me: me)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 7,
                                        child: _FeedColumn(
                                          me: me,
                                          postsGridView: _postsGridView,
                                          onToggleGrid: () => setState(() => _postsGridView = !_postsGridView),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _IntroCard(me: me),
                                  const SizedBox(height: 12),
                                  _FeedColumn(
                                    me: me,
                                    postsGridView: _postsGridView,
                                    onToggleGrid: () => setState(() => _postsGridView = !_postsGridView),
                                  ),
                                ],
                              );
                            },
                          )
                        else if (_profileSectionTab == 1)
                          _IntroCard(me: me, fullWidth: true)
                        else
                          _PlaceholderSection(
                            title: _tabLabel(_profileSectionTab),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tabLabel(int i) {
    const labels = ['Tất cả', 'Giới thiệu', 'Bạn bè', 'Ảnh', 'Reels'];
    return i < labels.length ? labels[i] : 'Trang';
  }
}

class _FitnetTopBar extends StatelessWidget {
  const _FitnetTopBar({
    required this.initial,
    required this.onBack,
    required this.onOpenMenu,
  });

  final String initial;
  final VoidCallback onBack;
  final VoidCallback onOpenMenu;

  static const Color _fbBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget navIcon(IconData icon, {bool selected = false, VoidCallback? onTap}) {
      return InkWell(
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng demo')));
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: selected ? _fbBlue : Colors.black54),
              if (selected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 48,
                  decoration: BoxDecoration(color: _fbBlue, borderRadius: BorderRadius.circular(2)),
                )
              else
                const SizedBox(height: 7),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4))),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 900;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
                    Text('Fitnet', style: theme.textTheme.titleLarge?.copyWith(color: _fbBlue, fontWeight: FontWeight.w900)),
                    if (!narrow) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm trên Fitnet',
                              prefixIcon: const Icon(Icons.search, size: 22),
                              filled: true,
                              fillColor: const Color(0xFFF0F2F5),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              isDense: true,
                            ),
                            onSubmitted: (_) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tìm kiếm (demo)')));
                            },
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (!narrow)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            navIcon(Icons.home_rounded, selected: false),
                            navIcon(Icons.people_alt_outlined),
                            navIcon(Icons.ondemand_video_outlined),
                            navIcon(Icons.storefront_outlined),
                            navIcon(Icons.groups_outlined),
                            navIcon(Icons.account_circle, selected: true),
                          ],
                        ),
                      )
                    else
                      const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.apps),
                      onPressed: onOpenMenu,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tin nhắn (demo)'))),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thông báo (demo)'))),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 4, left: 4),
                      child: CircleAvatar(
                        radius: 18,
                        child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CoverAndIdentity extends StatelessWidget {
  const _CoverAndIdentity({
    required this.me,
    required this.initial,
    required this.friendsCount,
    required this.onAddCover,
    required this.onAddStory,
    required this.onEditProfile,
  });

  final FitnetUser me;
  final String initial;
  final int friendsCount;
  final VoidCallback onAddCover;
  final VoidCallback onAddStory;
  final VoidCallback onEditProfile;

  static const Color _fbBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade400,
                      Colors.grey.shade600,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: FilledButton.tonalIcon(
                onPressed: onAddCover,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 1,
                ),
                label: const Text('Thêm ảnh bìa'),
              ),
            ),
            Positioned(
              left: 24,
              bottom: -36,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 72,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    initial,
                    style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        LayoutBuilder(
          builder: (context, c) {
            final row = c.maxWidth >= 560;
            final nameBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me.name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$friendsCount người bạn',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: onAddStory,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Thêm vào tin'),
                  style: FilledButton.styleFrom(backgroundColor: _fbBlue, foregroundColor: Colors.white),
                ),
                FilledButton.tonalIcon(
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE4E6EB),
                    foregroundColor: Colors.black87,
                  ),
                  label: const Text('Chỉnh sửa trang cá nhân'),
                ),
              ],
            );
            if (row) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: nameBlock),
                  actions,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                nameBlock,
                const SizedBox(height: 12),
                actions,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProfileSubTabs extends StatelessWidget {
  const _ProfileSubTabs({
    required this.selectedIndex,
    required this.onSelect,
    required this.onMore,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const tabs = ['Tất cả', 'Giới thiệu', 'Bạn bè', 'Ảnh', 'Reels'];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  _SubTabInk(
                    label: tabs[i],
                    selected: selectedIndex == i,
                    onTap: () => onSelect(i),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xem thêm (demo)')));
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      child: Row(
                        children: [
                          Text('Xem thêm', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                          Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.more_horiz), onPressed: onMore),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
        ],
      ),
    );
  }
}

class _SubTabInk extends StatelessWidget {
  const _SubTabInk({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _fbBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: selected ? _fbBlue : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (selected)
              Container(
                height: 3,
                width: 56,
                decoration: BoxDecoration(color: _fbBlue, borderRadius: BorderRadius.circular(2)),
              )
            else
              const SizedBox(height: 3),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.me, this.fullWidth = false});

  final FitnetUser me;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget row(IconData icon, String text) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Thông tin cá nhân',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 22),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sửa giới thiệu (demo)')));
                  },
                ),
              ],
            ),
            row(Icons.lock_outline, 'Sống ở Hà Nội'),
            row(Icons.house_outlined, 'Từ Nam Định'),
            row(Icons.cake_outlined, '6 tháng 2'),
            row(Icons.favorite_border, 'Độc thân'),
            row(Icons.wc_outlined, 'Nam'),
            const Divider(height: 24),
            row(Icons.email_outlined, me.email),
            row(Icons.badge_outlined, 'Vai trò: ${me.role}'),
          ],
        ),
      ),
    );
  }
}

class _FeedColumn extends StatelessWidget {
  const _FeedColumn({
    required this.me,
    required this.postsGridView,
    required this.onToggleGrid,
  });

  final FitnetUser me;
  final bool postsGridView;
  final VoidCallback onToggleGrid;

  static const Color _fbBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = (me.name.isNotEmpty ? me.name[0] : '?').toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo bài viết (demo)')));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Text('Bạn đang nghĩ gì?', style: theme.textTheme.bodyLarge),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ComposerMiniAction(
                        icon: Icons.videocam,
                        color: const Color(0xFFE41E3F),
                        label: 'Video trực tiếp',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Live (demo)'))),
                      ),
                    ),
                    Expanded(
                      child: _ComposerMiniAction(
                        icon: Icons.photo_library_outlined,
                        color: const Color(0xFF42B72A),
                        label: 'Ảnh/video',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ảnh/video (demo)'))),
                      ),
                    ),
                    Expanded(
                      child: _ComposerMiniAction(
                        icon: Icons.flag_outlined,
                        color: _fbBlue,
                        label: 'Cột mốc',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cột mốc (demo)'))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Bài viết', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    FilledButton.tonal(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bộ lọc (demo)'))),
                      child: const Text('Bộ lọc'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quản lý bài viết (demo)'))),
                      child: const Text('Quản lý bài viết'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: postsGridView ? onToggleGrid : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: postsGridView ? const Color(0xFFE4E6EB) : _fbBlue.withValues(alpha: 0.12),
                        ),
                        child: Text('Chế độ xem danh sách', style: TextStyle(color: postsGridView ? Colors.black54 : _fbBlue, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: postsGridView ? null : onToggleGrid,
                        style: FilledButton.styleFrom(
                          backgroundColor: !postsGridView ? const Color(0xFFE4E6EB) : _fbBlue.withValues(alpha: 0.12),
                        ),
                        child: Text('Chế độ xem lưới', style: TextStyle(color: !postsGridView ? Colors.black54 : _fbBlue, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  child: Text(
                    'Không có bài viết',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ComposerMiniAction extends StatelessWidget {
  const _ComposerMiniAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderSection extends StatelessWidget {
  const _PlaceholderSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            '$title — nội dung demo sẽ có sau.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
