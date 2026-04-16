import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/fitnet_user.dart';
import '../ui/fitnet_layout.dart';
import '../social/components/create_post_box.dart';
import '../social/components/post_card.dart';
import '../social/components/right_panel_card.dart';
import '../social/components/sidebar_item.dart';
import '../social/components/story_card.dart';
import 'exercise_ranking_cost_screen.dart';
import 'nearby_gyms_screen.dart';
import 'note_nodes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.api,
    required this.me,
    this.onOpenNearbyGyms,
  });

  final ApiClient api;
  final FitnetUser me;

  /// Mở màn phòng tập với cùng header Fitnet (do [UserAppShell] cung cấp).
  final VoidCallback? onOpenNearbyGyms;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _posts = const [];

  // Local (not persisted) interaction state.
  final Set<int> _liked = <int>{};
  final Map<int, int> _likeCounts = <int, int>{};
  final Map<int, List<String>> _comments = <int, List<String>>{};

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final json = await widget.api.getJson('/api/posts');
      final data = json['data'];
      final list = (data is List) ? data.cast<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];

      // Initialize interaction maps with defaults.
      final newLikeCounts = <int, int>{};
      for (final p in list) {
        final id = int.tryParse(p['id']?.toString() ?? '') ?? -1;
        if (id < 0) continue;
        newLikeCounts[id] = int.tryParse(p['like_count']?.toString() ?? '') ?? _likeCounts[id] ?? 0;
      }

      setState(() {
        _posts = list;
        _likeCounts.addAll(newLikeCounts);
      });
    } catch (_) {
      setState(() => _error = 'Không tải được bài post');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createPostFromBody(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final lines = trimmed.split(RegExp(r'\r?\n'));
    String title;
    String? content;

    if (lines.length == 1) {
      final line = lines.first;
      if (line.length <= 120) {
        title = line;
        content = null;
      } else {
        title = line.substring(0, 120);
        content = line.substring(120);
      }
    } else {
      title = lines.first.length > 120 ? lines.first.substring(0, 120) : lines.first;
      content = lines.sublist(1).join('\n').trim();
      if (content.isEmpty) content = null;
    }

    final payload = <String, dynamic>{'title': title};
    if (content != null && content.isNotEmpty) {
      payload['content'] = content;
    }

    await widget.api.postJson('/api/posts', payload);
    await _loadPosts();
  }

  Future<void> _openComposer() async {
    final text = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _CreatePostDialog(me: widget.me),
    );

    if (text != null && text.trim().isNotEmpty && mounted) {
      await _createPostFromBody(text);
    }
  }

  void _toggleLike(int postId) {
    setState(() {
      final has = _liked.contains(postId);
      if (has) {
        _liked.remove(postId);
        _likeCounts[postId] = (_likeCounts[postId] ?? 0) - 1;
      } else {
        _liked.add(postId);
        _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
      }
    });
  }

  Future<void> _openComments(int postId) async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final list = _comments[postId] ?? <String>[];
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bình luận',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: list.isEmpty
                          ? const Center(child: Text('Chưa có bình luận'))
                          : ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(list[i]),
                                );
                              },
                            ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: 'Nhập bình luận',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;
                            setState(() {
                              final existing = _comments[postId] ?? <String>[];
                              existing.add(text);
                              _comments[postId] = existing;
                            });
                            setStateSheet(() {});
                            controller.clear();
                          },
                          child: const Text('Gửi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const fbBg = Color(0xFFF5F7FA);

    return ColoredBox(
      color: fbBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          return RefreshIndicator(
            onRefresh: _loadPosts,
            child: wide
                ? _buildWideLayout(context, fbBg)
                : _buildNarrowLayout(context, fbBg),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, Color fbBg) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: FitnetLayout.maxContentWidth),
              child: Padding(
                padding: FitnetLayout.pagePadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: FitnetLayout.leftRailWidth, child: _LeftSidebar(me: widget.me)),
                    SizedBox(width: FitnetLayout.columnGap),
                    Expanded(
                      flex: 2,
                      child: _buildFeedColumn(context),
                    ),
                    SizedBox(width: FitnetLayout.columnGap),
                    SizedBox(
                      width: FitnetLayout.rightRailWidth,
                      child: _RightSidebar(
                        api: widget.api,
                        me: widget.me,
                        onOpenNearbyGyms: widget.onOpenNearbyGyms,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, Color fbBg) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _LeftSidebar(me: widget.me, compact: true),
        const SizedBox(height: 12),
        CreatePostBox(
          avatarText: (widget.me.name.isNotEmpty ? widget.me.name[0] : '?'),
          placeholder: 'Chia sẻ buổi tập hôm nay của bạn...',
          onTapCompose: _openComposer,
        ),
        const SizedBox(height: 10),
        _StoriesRow(me: widget.me),
        const SizedBox(height: 12),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        if (_error != null) Text(_error!),
        if (!_loading && _error == null && _posts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Chưa có bài post')),
          ),
        ..._postCards(context),
        const SizedBox(height: 20),
        _RightSidebar(
          api: widget.api,
          me: widget.me,
          onOpenNearbyGyms: widget.onOpenNearbyGyms,
        ),
      ],
    );
  }

  List<Widget> _postCards(BuildContext context) {
    return [
      for (final p in _posts)
        Builder(builder: (context) {
          final id = int.tryParse(p['id']?.toString() ?? '') ?? -1;
          if (id < 0) return const SizedBox.shrink();
          final createdAt = DateTime.tryParse(p['created_at']?.toString() ?? '');
          final timeText = createdAt == null ? '' : _relativeTime(createdAt);
          final userId = p['user_id']?.toString() ?? '';
          final authorLabel = userId.isEmpty ? 'Người dùng' : 'User #$userId';
          final authorAvatarText = (authorLabel.isNotEmpty ? authorLabel[0] : '?');

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Padding(
              key: ValueKey('post_$id'),
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(
                authorLabel: authorLabel,
                authorAvatarText: authorAvatarText,
                timeLabel: timeText.isEmpty ? 'Vừa xong' : timeText,
                title: p['title']?.toString() ?? '',
                body: p['content']?.toString() ?? '',
                likeCount: _likeCounts[id] ?? 0,
                liked: _liked.contains(id),
                onToggleLike: () => _toggleLike(id),
                onComment: () => _openComments(id),
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chia sẻ (demo)')));
                },
              ),
            ),
          );
        }),
    ];
  }

  Widget _buildFeedColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CreatePostBox(
          avatarText: (widget.me.name.isNotEmpty ? widget.me.name[0] : '?'),
          placeholder: 'Chia sẻ buổi tập hôm nay của bạn...',
          onTapCompose: _openComposer,
        ),
        const SizedBox(height: 10),
        _StoriesRow(me: widget.me),
        const SizedBox(height: 12),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        if (_error != null) Text(_error!),
        if (!_loading && _error == null && _posts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('Chưa có bài post')),
          ),
        ..._postCards(context),
      ],
    );
  }
}

class _LeftSidebar extends StatelessWidget {
  const _LeftSidebar({required this.me, this.compact = false});

  final FitnetUser me;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = (me.name.isNotEmpty ? me.name[0] : '?').toUpperCase();

    void tap(String label) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label (demo)')));

    if (compact) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(me.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final s in ['Bạn bè', 'Nhóm', 'Đã lưu'])
                  ActionChip(
                    label: Text(s),
                    onPressed: () {
                      tap(s);
                    },
                  ),
              ]),
            ],
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  foregroundColor: theme.colorScheme.primary,
                  child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(me.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SidebarItem(icon: Icons.people_alt_outlined, label: 'Bạn bè', onTap: () => tap('Bạn bè')),
        const SizedBox(height: 6),
        SidebarItem(icon: Icons.bookmark_outline, label: 'Đã lưu', onTap: () => tap('Đã lưu')),
        const SizedBox(height: 6),
        SidebarItem(icon: Icons.groups_outlined, label: 'Nhóm', onTap: () => tap('Nhóm')),
        const SizedBox(height: 12),
        Text('Lối tắt của bạn', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        SidebarItem(icon: Icons.fitness_center, label: 'Fitnet Gym', onTap: () => tap('Fitnet Gym')),
        const SizedBox(height: 6),
        SidebarItem(icon: Icons.event_outlined, label: 'Sự kiện tập luyện', onTap: () => tap('Sự kiện tập luyện')),
      ],
    );
  }
}

class _RightSidebar extends StatelessWidget {
  const _RightSidebar({
    required this.api,
    required this.me,
    this.onOpenNearbyGyms,
  });

  final ApiClient api;
  final FitnetUser me;
  final VoidCallback? onOpenNearbyGyms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget sectionTitle(String t) => Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(t, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        );

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        sectionTitle('Dành cho bạn'),
        RightPanelCard(
          icon: Icons.map_outlined,
          iconColor: theme.colorScheme.primary,
          title: 'Phòng tập gần bạn',
          subtitle: 'Xem bản đồ và phòng gym quanh khu vực',
          onTap: () {
            if (onOpenNearbyGyms != null) {
              onOpenNearbyGyms!();
            } else {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Phòng tập gần bạn')),
                    body: NearbyGymsScreen(api: api),
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),
        RightPanelCard(
          icon: Icons.hub_outlined,
          iconColor: const Color(0xFF16A34A),
          title: 'Node học tập',
          subtitle: 'Lưu ghi chú video, ảnh hoặc chữ',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NoteNodesScreen())),
        ),
        const SizedBox(height: 10),
        RightPanelCard(
          icon: Icons.leaderboard_outlined,
          iconColor: const Color(0xFFDC2626),
          title: 'Ranking cost bài tập',
          subtitle: 'So sánh mức “cost” giữa các bài tập',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ExerciseRankingCostScreen(api: api, me: me),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoriesRow extends StatelessWidget {
  const _StoriesRow({required this.me});

  final FitnetUser me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = (me.name.isNotEmpty ? me.name[0] : '?').toUpperCase();

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return StoryCard(
              title: 'Tạo tin',
              subtitle: 'Story',
              avatarText: initial,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.95),
                  const Color(0xFF06B6D4).withValues(alpha: 0.95),
                ],
              ),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo tin (demo)'))),
            );
          }
          return StoryCard(
            title: i == 1 ? me.name : 'Bạn $i',
            subtitle: 'New',
            avatarText: i == 1 ? initial : '?',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF60A5FA).withValues(alpha: 0.95),
                const Color(0xFF1D4ED8).withValues(alpha: 0.95),
              ],
            ),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xem tin #$i (demo)'))),
          );
        },
      ),
    );
  }
}

class _CreatePostDialog extends StatefulWidget {
  const _CreatePostDialog({required this.me});

  final FitnetUser me;

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final _textCtrl = TextEditingController();
  String _privacy = 'Bạn bè cụ thể';

  static const Color _fbBlue = Color(0xFF1877F2);

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  bool get _canPost => _textCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.me.name;
    final nameParts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'Bạn';

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Tạo bài viết',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFE4E6EB),
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(36, 36),
                        ),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      child: Text(
                        (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          PopupMenuButton<String>(
                            offset: const Offset(0, 28),
                            onSelected: (v) => setState(() => _privacy = v),
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'Công khai', child: Text('Công khai')),
                              PopupMenuItem(value: 'Bạn bè', child: Text('Bạn bè')),
                              PopupMenuItem(value: 'Bạn bè cụ thể', child: Text('Bạn bè cụ thể')),
                              PopupMenuItem(value: 'Chỉ mình tôi', child: Text('Chỉ mình tôi')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE4E6EB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_alt_outlined, size: 16, color: Colors.grey.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    _privacy,
                                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade800),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _textCtrl,
                  maxLines: null,
                  minLines: 4,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: '$firstName ơi, bạn đang nghĩ gì thế?',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 22),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Màu nền bài viết (demo)')));
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF6B9D), Color(0xFFFFA500), Color(0xFF4A90D9)],
                          ),
                        ),
                        child: const Text('Aa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emoji (demo)')));
                      },
                      icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            'Thêm vào bài viết của bạn',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _PostToolbarIcon(
                              icon: Icons.photo_library_outlined,
                              color: const Color(0xFF42B72A),
                              tooltip: 'Ảnh/video',
                            ),
                            _PostToolbarIcon(
                              icon: Icons.person_add_alt_outlined,
                              color: _fbBlue,
                              tooltip: 'Gắn thẻ bạn bè',
                            ),
                            _PostToolbarIcon(
                              icon: Icons.emoji_emotions_outlined,
                              color: const Color(0xFFFFC107),
                              tooltip: 'Cảm xúc',
                            ),
                            _PostToolbarIcon(
                              icon: Icons.place_outlined,
                              color: const Color(0xFFE41E3F),
                              tooltip: 'Check-in',
                            ),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GIF (demo)')));
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF009688).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('GIF', style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.w800, fontSize: 12)),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm tuỳ chọn (demo)')));
                              },
                              icon: Icon(Icons.more_horiz, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canPost ? () => Navigator.pop(context, _textCtrl.text) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _canPost ? _fbBlue : const Color(0xFFE4E6EB),
                      foregroundColor: _canPost ? Colors.white : Colors.grey.shade500,
                      disabledBackgroundColor: const Color(0xFFE4E6EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      'Đăng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _canPost ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostToolbarIcon extends StatelessWidget {
  const _PostToolbarIcon({required this.icon, required this.color, required this.tooltip});

  final IconData icon;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$tooltip (demo)')));
      },
      icon: Icon(icon, color: color, size: 22),
    );
  }
}

String _relativeTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  return '${diff.inDays} ngày trước';
}

