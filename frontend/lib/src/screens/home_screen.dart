import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/fitnet_user.dart';
import '../ui/fitnet_layout.dart';
import '../social/components/create_post_box.dart';
import '../social/components/post_card.dart';
import '../social/components/right_panel_card.dart';
import '../social/components/sidebar_item.dart';
import '../social/components/story_card.dart';
import 'exercise_post_detail_screen.dart';
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
  bool _exerciseOnly = false;

  // Local (not persisted) interaction state.
  final Set<int> _liked = <int>{};
  final Map<int, int> _likeCounts = <int, int>{};

  /// Chỉ dùng layout rộng: thanh scroll vẽ ở mép phải viewport (ngoài khối 3 cột).
  final ScrollController _wideFeedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _wideFeedScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final path = _exerciseOnly ? '/api/posts?kind=exercise' : '/api/posts';
      final json = await widget.api.getJson(path);
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

  Future<void> _createPostFromPayload(Map<String, dynamic> payload) async {
    try {
      await widget.api.postJson('/api/posts', payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đăng bài')));
      await _loadPosts();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đăng bài thất bại: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đăng bài thất bại: $e')));
    }
  }

  Future<void> _openComposer() async {
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _CreatePostDialog(me: widget.me),
    );

    if (res != null && mounted) {
      await _createPostFromPayload(res);
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

  Future<void> _openComments(int postId, {required bool isExercisePost}) async {
    if (!isExercisePost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment chỉ bật cho bài đăng bài tập.')));
      return;
    }

    final controller = TextEditingController();
    List<Map<String, dynamic>> remote = const [];
    bool loading = true;
    String? error;

    Future<void> load() async {
      loading = true;
      error = null;
      try {
        final json = await widget.api.getJson('/api/posts/$postId/comments');
        final data = json['data'];
        remote = (data is List) ? data.cast<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
      } catch (e) {
        error = e.toString();
      } finally {
        loading = false;
      }
    }

    await load();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final list = remote;
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
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : (error != null
                              ? Center(child: Text(error!))
                              : (list.isEmpty
                                  ? const Center(child: Text('Chưa có bình luận'))
                                  : ListView.builder(
                                      itemCount: list.length,
                                      itemBuilder: (context, i) {
                                        final c = list[i];
                                        final body = (c['body'] ?? '').toString();
                                        final userId = (c['user_id'] ?? '').toString();
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Text(userId.isEmpty ? body : 'User #$userId: $body'),
                                        );
                                      },
                                    ))),
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
                          onPressed: () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;
                            try {
                              await widget.api.postJson('/api/posts/$postId/comments', {'body': text});
                              controller.clear();
                              await load();
                              setStateSheet(() {});
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Gửi failed: $e')));
                            }
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

  Future<void> _rateExercisePost(int postId, int stars) async {
    try {
      await widget.api.postJson('/api/posts/$postId/rating', {'stars': stars});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã vote $stars sao')));
      await _loadPosts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vote failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const fbBg = Color(0xFFF5F7FA);

    return ColoredBox(
      color: fbBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          if (wide) {
            return _buildWideLayout(context, fbBg, constraints);
          }
          return RefreshIndicator(
            onRefresh: _loadPosts,
            child: _buildNarrowLayout(context, fbBg),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, Color fbBg, BoxConstraints layoutConstraints) {
    final viewportH = layoutConstraints.maxHeight.isFinite && layoutConstraints.maxHeight > 0
        ? layoutConstraints.maxHeight
        : MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: viewportH,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: FitnetLayout.maxContentWidth),
              child: Padding(
                padding: FitnetLayout.pagePadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: FitnetLayout.leftRailWidth,
                      child: SingleChildScrollView(
                        clipBehavior: Clip.hardEdge,
                        child: _LeftSidebar(me: widget.me, pinnedRail: true),
                      ),
                    ),
                    SizedBox(width: FitnetLayout.columnGap),
                    Expanded(
                      flex: 2,
                      child: RefreshIndicator(
                        onRefresh: _loadPosts,
                        child: ScrollConfiguration(
                          behavior: const _WideHomeScrollBehavior(),
                          child: CustomScrollView(
                            controller: _wideFeedScrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(child: _buildFeedColumn(context)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: FitnetLayout.columnGap),
                    SizedBox(
                      width: FitnetLayout.rightRailWidth,
                      child: SingleChildScrollView(
                        clipBehavior: Clip.hardEdge,
                        child: _RightSidebar(
                          api: widget.api,
                          me: widget.me,
                          onOpenNearbyGyms: widget.onOpenNearbyGyms,
                          pinnedRail: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Mép ngoài viewport: right âm để thumb nằm ngoài khối 3 cột (Stack clipBehavior: none).
          Positioned(
            right: -6,
            top: 0,
            bottom: 0,
            width: 14,
            child: RawScrollbar(
              controller: _wideFeedScrollController,
              thickness: 6,
              radius: const Radius.circular(3),
              thumbVisibility: true,
              child: const ColoredBox(
                color: Colors.transparent,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, Color fbBg) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                selected: _exerciseOnly,
                label: const Text('Chỉ bài tập'),
                onSelected: (v) async {
                  setState(() => _exerciseOnly = v);
                  await _loadPosts();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
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
          final kind = (p['kind'] ?? 'normal').toString();
          final isExercisePost = kind == 'exercise';
          final ex = p['exercise'];
          final exerciseName = (ex is Map && ex['name'] != null) ? ex['name'].toString().trim() : '';
          final ratingAvg = (p['rating_avg'] is num) ? (p['rating_avg'] as num).toDouble() : double.tryParse(p['rating_avg']?.toString() ?? '');
          final ratingCount = int.tryParse(p['rating_count']?.toString() ?? '') ?? 0;

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
                badgeLabel: isExercisePost ? 'Bài tập' : null,
                exerciseName: isExercisePost && exerciseName.isNotEmpty ? exerciseName : null,
                ratingAvg: isExercisePost ? ratingAvg : null,
                ratingCount: isExercisePost ? ratingCount : null,
                onRate: isExercisePost ? (stars) => _rateExercisePost(id, stars) : null,
                likeCount: _likeCounts[id] ?? 0,
                liked: _liked.contains(id),
                onToggleLike: () => _toggleLike(id),
                onComment: () => _openComments(id, isExercisePost: isExercisePost),
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chia sẻ (demo)')));
                },
                onCardTap: isExercisePost
                    ? () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => ExercisePostDetailScreen(api: widget.api, postId: id),
                          ),
                        )
                    : null,
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
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                selected: _exerciseOnly,
                label: const Text('Chỉ bài tập'),
                onSelected: (v) async {
                  setState(() => _exerciseOnly = v);
                  await _loadPosts();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
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
  const _LeftSidebar({required this.me, this.compact = false, this.pinnedRail = false});

  final FitnetUser me;
  final bool compact;
  /// Cột trái nằm ngoài feed cuộn: dùng [Column] để bọc trong [SingleChildScrollView] riêng.
  final bool pinnedRail;

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

    final railChildren = <Widget>[
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
    ];

    if (pinnedRail) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: railChildren,
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: railChildren,
    );
  }
}

class _RightSidebar extends StatelessWidget {
  const _RightSidebar({
    required this.api,
    required this.me,
    this.onOpenNearbyGyms,
    this.pinnedRail = false,
  });

  final ApiClient api;
  final FitnetUser me;
  final VoidCallback? onOpenNearbyGyms;
  final bool pinnedRail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget sectionTitle(String t) => Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(t, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        );

    final railChildren = <Widget>[
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
        subtitle: 'Xếp hạng bài tập theo số vote',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExerciseRankingCostScreen(api: api, me: me),
          ),
        ),
      ),
    ];

    if (pinnedRail) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: railChildren,
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: railChildren,
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
  bool _isExercisePost = false;

  final _exerciseNameCtrl = TextEditingController();
  String _exerciseType = 'strength';
  int _exerciseDifficulty = 2;
  final _exerciseMetCtrl = TextEditingController();

  static const Color _fbBlue = Color(0xFF1877F2);

  @override
  void initState() {
    super.initState();
    void refresh() {
      if (mounted) setState(() {});
    }

    _textCtrl.addListener(refresh);
    _exerciseNameCtrl.addListener(refresh);
    _exerciseMetCtrl.addListener(refresh);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _exerciseNameCtrl.dispose();
    _exerciseMetCtrl.dispose();
    super.dispose();
  }

  bool get _canPost {
    if (_textCtrl.text.trim().isEmpty) return false;
    if (!_isExercisePost) return true;
    return _exerciseNameCtrl.text.trim().isNotEmpty;
  }

  Map<String, dynamic> _payloadFromText() {
    final trimmed = _textCtrl.text.trim();
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

    final payload = <String, dynamic>{
      'kind': _isExercisePost ? 'exercise' : 'normal',
      'title': title,
    };
    if (content != null && content.isNotEmpty) {
      payload['content'] = content;
    }

    if (_isExercisePost) {
      final met = num.tryParse(_exerciseMetCtrl.text.trim());
      payload['exercise'] = <String, dynamic>{
        'name': _exerciseNameCtrl.text.trim(),
        'type': _exerciseType,
        'difficulty': _exerciseDifficulty,
        'met': met,
      };
      if (met == null) {
        (payload['exercise'] as Map<String, dynamic>).remove('met');
      }
    }

    return payload;
  }

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
                          const SizedBox(height: 10),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text('Bài thường'), icon: Icon(Icons.article_outlined)),
                              ButtonSegment(value: true, label: Text('Bài tập'), icon: Icon(Icons.fitness_center_outlined)),
                            ],
                            selected: {_isExercisePost},
                            onSelectionChanged: (s) => setState(() => _isExercisePost = s.first),
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
              if (_isExercisePost) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _exerciseNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên bài tập (bắt buộc)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _exerciseType,
                              items: const [
                                DropdownMenuItem(value: 'strength', child: Text('Strength')),
                                DropdownMenuItem(value: 'cardio', child: Text('Cardio')),
                                DropdownMenuItem(value: 'hiit', child: Text('HIIT')),
                                DropdownMenuItem(value: 'bodyweight', child: Text('Bodyweight')),
                              ],
                              onChanged: (v) => setState(() => _exerciseType = v ?? 'strength'),
                              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _exerciseDifficulty,
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('Dễ (1)')),
                                DropdownMenuItem(value: 2, child: Text('Vừa (2)')),
                                DropdownMenuItem(value: 3, child: Text('Khá (3)')),
                                DropdownMenuItem(value: 4, child: Text('Khó (4)')),
                                DropdownMenuItem(value: 5, child: Text('Rất khó (5)')),
                              ],
                              onChanged: (v) => setState(() => _exerciseDifficulty = v ?? 2),
                              decoration: const InputDecoration(labelText: 'Độ khó', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _exerciseMetCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'MET (tuỳ chọn, cardio/hiit)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bài tập sẽ được gửi để Admin duyệt trước khi xuất hiện trong danh sách bài tập.',
                        style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
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
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_textCtrl, _exerciseNameCtrl, _exerciseMetCtrl]),
                    builder: (context, _) {
                      final canPost = _canPost;
                      return FilledButton(
                        onPressed: canPost ? () => Navigator.pop(context, _payloadFromText()) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: canPost ? _fbBlue : const Color(0xFFE4E6EB),
                          foregroundColor: canPost ? Colors.white : Colors.grey.shade500,
                          disabledBackgroundColor: const Color(0xFFE4E6EB),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          'Đăng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: canPost ? Colors.white : Colors.grey.shade500,
                          ),
                        ),
                      );
                    },
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

/// Tắt scrollbar mặc định của Material (desktop/web) bọc trong [Scrollable] — chỉ dùng [RawScrollbar] ngoài cùng.
class _WideHomeScrollBehavior extends MaterialScrollBehavior {
  const _WideHomeScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
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

