import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../ui/fitnet_layout.dart';

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  final _searchCtrl = TextEditingController();
  String _statusFilter = 'All Status';
  String _typeFilter = 'All Types';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await widget.api.getJson('/api/posts');
      final data = json['data'];
      final list = (data is List) ? data.cast<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
      setState(() => _items = list);
    } catch (_) {
      setState(() => _error = 'Không tải được posts');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editPost(Map<String, dynamic> p) async {
    final id = p['id'];
    final title = p['title']?.toString() ?? '';
    final content = p['content']?.toString() ?? '';

    final titleCtrl = TextEditingController(text: title);
    final contentCtrl = TextEditingController(text: content);

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa post'),
          content: SizedBox(
            width: (MediaQuery.sizeOf(context).width - 48).clamp(280.0, 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
                  minLines: 3,
                  maxLines: 6,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
          ],
        );
      },
    );

    if (ok != true) return;

    await widget.api.putJson('/api/posts/$id', {
      'title': titleCtrl.text.trim(),
      'content': contentCtrl.text.trim(),
    });
    await _load();
  }

  Future<void> _deletePost(Map<String, dynamic> p) async {
    final id = p['id'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa post?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;

    await widget.api.deleteJson('/api/posts/$id');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final useCards = FitnetBreakpoints.useAdminCards(screenW);
    final compactHeader = FitnetBreakpoints.isCompactWidth(screenW);
    final q = _searchCtrl.text.trim().toLowerCase();

    final filtered = _items.where((p) {
      final title = (p['title'] ?? '').toString().toLowerCase();
      final content = (p['content'] ?? '').toString().toLowerCase();
      final kind = (p['kind'] ?? 'normal').toString().toLowerCase();
      final typeLabel = kind == 'exercise' ? 'Exercise' : 'Post';
      final status = (p['status'] ?? 'Published').toString();

      if (q.isNotEmpty && !(title.contains(q) || content.contains(q))) return false;
      if (_typeFilter != 'All Types' && typeLabel.toLowerCase() != _typeFilter.toLowerCase()) return false;
      if (_statusFilter != 'All Status' && status.toLowerCase() != _statusFilter.toLowerCase()) return false;
      return true;
    }).toList();

    int asInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    DateTime? asDate(dynamic v) => DateTime.tryParse(v?.toString() ?? '');

    final now = DateTime.now();
    final totalPosts = _items.length;
    final todayPosts = _items.where((p) {
      final dt = asDate(p['created_at'] ?? p['createdAt']);
      if (dt == null) return false;
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    }).length;
    final totalLikes = _items.fold<int>(0, (sum, p) => sum + asInt(p['like_count'] ?? p['likes'] ?? 0));
    final uniqueAuthors = _items.map((p) => (p['user_id'] ?? p['userId'] ?? '').toString()).where((s) => s.isNotEmpty).toSet().length;

    Widget statCard({
      required String title,
      required String value,
      required String subtitle,
      required Color color,
      required IconData icon,
    }) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF64748B), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget pill(String text, {required Color bg, required Color fg}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
      );
    }

    Widget pageHeader() {
      final buttons = Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export report (demo)')));
            },
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export Report'),
          ),
        ],
      );

      if (compactHeader) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Post Management', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Monitor posts and content moderation',
              style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            buttons,
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Post Management', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Monitor posts and content moderation',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          buttons,
        ],
      );
    }

    Widget historyCard() {
      final statuses = <String>['All Status', 'Published', 'Hidden', 'Flagged'];
      final types = <String>['All Types', 'Post', 'Exercise'];

      final search = TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by title or content...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
        ),
      );

      final statusDd = DropdownButtonFormField<String>(
        key: ValueKey('postStatusFilter_$_statusFilter'),
        initialValue: _statusFilter,
        items: [for (final s in statuses) DropdownMenuItem(value: s, child: Text(s))],
        onChanged: (v) => setState(() => _statusFilter = v ?? 'All Status'),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
          isDense: true,
        ),
      );

      final typeDd = DropdownButtonFormField<String>(
        key: ValueKey('postTypeFilter_$_typeFilter'),
        initialValue: _typeFilter,
        items: [for (final t in types) DropdownMenuItem(value: t, child: Text(t))],
        onChanged: (v) => setState(() => _typeFilter = v ?? 'All Types'),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
          isDense: true,
        ),
      );

      Widget headerCell(String t, int flex) {
        return Expanded(
          flex: flex,
          child: Text(
            t,
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6, color: const Color(0xFF475569)),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }

      Widget cell(Widget child, int flex, {Alignment align = Alignment.centerLeft}) {
        return Expanded(flex: flex, child: Align(alignment: align, child: child));
      }

      String formatDate(dynamic raw) {
        final dt = asDate(raw);
        if (dt == null) return '';
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }

      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Post History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Manage posts and moderation logs',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 860;
                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        search,
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: statusDd),
                            const SizedBox(width: 10),
                            Expanded(child: typeDd),
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 12),
                      SizedBox(width: 160, child: statusDd),
                      const SizedBox(width: 12),
                      SizedBox(width: 160, child: typeDd),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: useCards
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                            const SizedBox(height: 12),
                            FilledButton(onPressed: _load, child: const Text('Thử lại')),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
                            const SizedBox(width: 10),
                            FilledButton(onPressed: _load, child: const Text('Thử lại')),
                          ],
                        ),
                )
              else if (useCards)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Không có post phù hợp bộ lọc',
                          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                        ),
                      )
                    else
                      for (final p in filtered)
                        Builder(
                          builder: (context) {
                            final id = (p['id'] ?? '').toString();
                            final kindLabel = (p['kind'] ?? 'normal').toString();
                            final ex = p['exercise'];
                            final exerciseLabel = (ex is Map && (ex['name'] ?? '').toString().trim().isNotEmpty)
                                ? (ex['name'] as Object).toString()
                                : () {
                                    final eid = int.tryParse(p['exercise_id']?.toString() ?? '') ?? 0;
                                    return eid > 0 ? 'ID $eid' : '—';
                                  }();
                            final title = (p['title'] ?? '(no title)').toString();
                            final author = (p['user_id'] ?? p['userId'] ?? '').toString();
                            final likes = asInt(p['like_count'] ?? p['likes'] ?? 0);
                            final dateText = formatDate(p['created_at'] ?? p['createdAt']);
                            final status = (p['status'] ?? 'Published').toString();

                            final statusChip = switch (status.toLowerCase()) {
                              'hidden' => pill('Hidden', bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E)),
                              'flagged' => pill('Flagged', bg: const Color(0xFFFEE2E2), fg: const Color(0xFF991B1B)),
                              _ => pill('Published', bg: const Color(0xFF0F172A), fg: Colors.white),
                            };

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        PopupMenuButton<_PostAction>(
                                          tooltip: 'Actions',
                                          icon: const Icon(Icons.more_horiz),
                                          onSelected: (a) async {
                                            if (a == _PostAction.edit) {
                                              await _editPost(p);
                                            } else if (a == _PostAction.delete) {
                                              await _deletePost(p);
                                            } else if (a == _PostAction.hide) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hide (demo)')));
                                            } else if (a == _PostAction.flag) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flag (demo)')));
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(value: _PostAction.edit, child: Text('Edit')),
                                            PopupMenuItem(value: _PostAction.hide, child: Text('Hide (demo)')),
                                            PopupMenuItem(value: _PostAction.flag, child: Text('Flag (demo)')),
                                            PopupMenuDivider(),
                                            PopupMenuItem(value: _PostAction.delete, child: Text('Delete')),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('ID $id • $kindLabel', style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B))),
                                    const SizedBox(height: 4),
                                    Text('Exercise: $exerciseLabel', style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF475569))),
                                    const SizedBox(height: 4),
                                    Text('Author: ${author.isEmpty ? '-' : author} • Likes: $likes • $dateText',
                                        style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B))),
                                    const SizedBox(height: 10),
                                    statusChip,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ],
                )
              else
                LayoutBuilder(
                  builder: (context, c) {
                    final maxTableHeight = (MediaQuery.of(context).size.height - 420).clamp(240.0, 620.0);
                    final vertical = ScrollController();

                    return SizedBox(
                      height: maxTableHeight,
                      child: Scrollbar(
                        controller: vertical,
                        thumbVisibility: true,
                        trackVisibility: true,
                        interactive: true,
                        child: SingleChildScrollView(
                          controller: vertical,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    color: const Color(0xFFF8FAFC),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        headerCell('POST ID', 2),
                                        const SizedBox(width: 12),
                                        headerCell('KIND', 2),
                                        const SizedBox(width: 12),
                                        headerCell('EXERCISE', 3),
                                        const SizedBox(width: 12),
                                        headerCell('TITLE', 3),
                                        const SizedBox(width: 12),
                                        headerCell('AUTHOR', 2),
                                        const SizedBox(width: 12),
                                        headerCell('LIKES', 2),
                                        const SizedBox(width: 12),
                                        headerCell('DATE', 2),
                                        const SizedBox(width: 12),
                                        headerCell('STATUS', 2),
                                        const SizedBox(width: 12),
                                        headerCell('ACTIONS', 1),
                                      ],
                                    ),
                                  ),
                                  if (filtered.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 26),
                                      child: Text(
                                        'Không có post phù hợp bộ lọc',
                                        style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                                      ),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: filtered.length,
                                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                                      itemBuilder: (context, i) {
                                        final p = filtered[i];
                                        final id = (p['id'] ?? '').toString();
                                        final kindLabel = (p['kind'] ?? 'normal').toString();
                                        final ex = p['exercise'];
                                        final exerciseLabel = (ex is Map && (ex['name'] ?? '').toString().trim().isNotEmpty)
                                            ? (ex['name'] as Object).toString()
                                            : () {
                                                final eid = int.tryParse(p['exercise_id']?.toString() ?? '') ?? 0;
                                                return eid > 0 ? 'ID $eid' : '—';
                                              }();
                                        final title = (p['title'] ?? '(no title)').toString();
                                        final author = (p['user_id'] ?? p['userId'] ?? '').toString();
                                        final likes = asInt(p['like_count'] ?? p['likes'] ?? 0);
                                        final dateText = formatDate(p['created_at'] ?? p['createdAt']);
                                        final status = (p['status'] ?? 'Published').toString();

                                        final statusChip = switch (status.toLowerCase()) {
                                          'hidden' => pill('Hidden', bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E)),
                                          'flagged' => pill('Flagged', bg: const Color(0xFFFEE2E2), fg: const Color(0xFF991B1B)),
                                          _ => pill('Published', bg: const Color(0xFF0F172A), fg: Colors.white),
                                        };

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          child: Row(
                                            children: [
                                              cell(Text(id, overflow: TextOverflow.ellipsis), 2),
                                              const SizedBox(width: 12),
                                              cell(Text(kindLabel, overflow: TextOverflow.ellipsis), 2),
                                              const SizedBox(width: 12),
                                              cell(
                                                Text(
                                                  exerciseLabel,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF475569)),
                                                ),
                                                3,
                                              ),
                                              const SizedBox(width: 12),
                                              cell(
                                                Text(
                                                  title,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                                ),
                                                3,
                                              ),
                                              const SizedBox(width: 12),
                                              cell(Text(author.isEmpty ? '-' : author, overflow: TextOverflow.ellipsis), 2),
                                              const SizedBox(width: 12),
                                              cell(Text(likes.toString(), overflow: TextOverflow.ellipsis), 2),
                                              const SizedBox(width: 12),
                                              cell(Text(dateText, overflow: TextOverflow.ellipsis), 2),
                                              const SizedBox(width: 12),
                                              cell(statusChip, 2),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                flex: 1,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: PopupMenuButton<_PostAction>(
                                                    tooltip: 'Actions',
                                                    icon: const Icon(Icons.more_horiz),
                                                    onSelected: (a) async {
                                                      if (a == _PostAction.edit) {
                                                        await _editPost(p);
                                                      } else if (a == _PostAction.delete) {
                                                        await _deletePost(p);
                                                      } else if (a == _PostAction.hide) {
                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hide (demo)')));
                                                      } else if (a == _PostAction.flag) {
                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flag (demo)')));
                                                      }
                                                    },
                                                    itemBuilder: (context) => const [
                                                      PopupMenuItem(value: _PostAction.edit, child: Text('Edit')),
                                                      PopupMenuItem(value: _PostAction.hide, child: Text('Hide (demo)')),
                                                      PopupMenuItem(value: _PostAction.flag, child: Text('Flag (demo)')),
                                                      PopupMenuDivider(),
                                                      PopupMenuItem(value: _PostAction.delete, child: Text('Delete')),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: FitnetBreakpoints.pagePaddingInsets(screenW),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          pageHeader(),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 980;
              final cards = [
                statCard(
                  title: 'Total Posts',
                  value: totalPosts.toString(),
                  subtitle: 'All time',
                  color: const Color(0xFF2563EB),
                  icon: Icons.article_outlined,
                ),
                statCard(
                  title: 'Published Today',
                  value: todayPosts.toString(),
                  subtitle: 'Today',
                  color: const Color(0xFF16A34A),
                  icon: Icons.today_outlined,
                ),
                statCard(
                  title: 'Total Likes',
                  value: totalLikes.toString(),
                  subtitle: 'Across all posts',
                  color: const Color(0xFFDC2626),
                  icon: Icons.thumb_up_alt_outlined,
                ),
                statCard(
                  title: 'Authors',
                  value: uniqueAuthors.toString(),
                  subtitle: 'Unique users',
                  color: const Color(0xFF0F172A),
                  icon: Icons.people_alt_outlined,
                ),
              ];

              if (narrow) {
                return Column(
                  children: [
                    for (final w in cards) ...[
                      w,
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          historyCard(),
        ],
      ),
    );
  }
}

enum _PostAction { edit, hide, flag, delete }

