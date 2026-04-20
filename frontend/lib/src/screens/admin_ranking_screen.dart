import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../ui/fitnet_layout.dart';
import 'exercise_post_detail_screen.dart';

/// Chỉ ranking bài đăng bài tập theo vote (đồng bộ với feed / Quản lý bài tập).
class AdminRankingScreen extends StatefulWidget {
  const AdminRankingScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<AdminRankingScreen> createState() => _AdminRankingScreenState();
}

class _AdminRankingScreenState extends State<AdminRankingScreen> {
  bool _loading = true;
  String? _error;
  String _period = 'week';
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _voteSubtitle(Map<String, dynamic> r) {
    final ex = r['exercise'];
    final name = (ex is Map && ex['name'] != null) ? ex['name'].toString().trim() : '';
    final avg = r['rating_avg'];
    final votes = r['rating_count'] ?? 0;
    if (name.isNotEmpty) {
      return 'Bài tập: $name • avg: $avg ★ • $votes vote';
    }
    return 'avg: $avg ★ • $votes vote';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await widget.api.getJson('/api/admin/leaderboards/exercise-posts/votes?period=$_period');
      final data = json['data'];
      final list =
          (data is List) ? data.cast<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
      setState(() => _rows = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPost(int postId) {
    if (postId <= 0) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ExercisePostDetailScreen(api: widget.api, postId: postId),
      ),
    );
  }

  Widget _periodDropdown(bool compact, bool enabled) {
    final labels = compact
        ? const ['Hôm nay', 'Tuần này', 'Tháng này', 'Mọi thời điểm']
        : const ['Today', 'This week', 'This month', 'All time'];
    return DropdownButton<String>(
      value: _period,
      isExpanded: compact,
      borderRadius: BorderRadius.circular(12),
      padding: compact ? const EdgeInsets.symmetric(horizontal: 4) : null,
      onChanged: !enabled
          ? null
          : (v) {
              if (v == null) return;
              setState(() => _period = v);
              _load();
            },
      items: [
        DropdownMenuItem(value: 'day', child: Text(labels[0])),
        DropdownMenuItem(value: 'week', child: Text(labels[1])),
        DropdownMenuItem(value: 'month', child: Text(labels[2])),
        DropdownMenuItem(value: 'all', child: Text(labels[3])),
      ],
    );
  }

  Widget _header(ThemeData theme, bool compact) {
    final titleStyle = (compact ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)
        ?.copyWith(fontWeight: FontWeight.w900);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ranking bài đăng (vote)', style: titleStyle),
          const SizedBox(height: 10),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Khoảng thời gian',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              isDense: true,
            ),
            child: _periodDropdown(true, !_loading),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Ranking bài đăng (vote)',
            style: titleStyle,
          ),
        ),
        _periodDropdown(false, !_loading),
      ],
    );
  }

  Widget _rankRow(ThemeData theme, Map<String, dynamic> r, bool compact) {
    final postId = int.tryParse(r['post_id']?.toString() ?? '') ?? 0;
    final title = (r['title'] ?? 'Unknown').toString();
    final votes = r['rating_count'] ?? 0;
    final rank = '${r['rank'] ?? ''}';

    final avatar = CircleAvatar(
      radius: compact ? 16 : 14,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      foregroundColor: theme.colorScheme.primary,
      child: Text(rank, style: TextStyle(fontWeight: FontWeight.w900, fontSize: compact ? 12 : 11)),
    );

    final voteChip = Chip(
      label: Text('$votes vote'),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    void onTap() => _openPost(postId);

    if (!compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: avatar,
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_voteSubtitle(r)),
            trailing: voteChip,
            onTap: onTap,
          ),
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _voteSubtitle(r),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        voteChip,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
      ],
    );
  }

  Widget _errorCard(ThemeData theme, bool compact) {
    if (compact) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_error!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text(_error!)),
            const SizedBox(width: 10),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        final compact = FitnetBreakpoints.isCompactWidth(c.maxWidth);
        final pad = EdgeInsets.fromLTRB(
          compact ? 16 : 24,
          compact ? 8 : 24,
          compact ? 16 : 24,
          compact ? 20 : 24,
        );

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: pad,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _header(theme, compact),
              const SizedBox(height: 8),
              Text(
                'Cùng dữ liệu với bảng xếp hạng trên app user; tên bài tập lấy từ Quản lý bài tập.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: compact ? 1.4 : null,
                ),
              ),
              const SizedBox(height: 16),
              if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              if (!_loading && _error != null) _errorCard(theme, compact),
              if (!_loading && _error == null)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final r in _rows) _rankRow(theme, r, compact),
                    ],
                  ),
                ),
              if (!_loading && _error == null && _rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Chưa có bài đăng bài tập được vote trong khoảng thời gian này.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
