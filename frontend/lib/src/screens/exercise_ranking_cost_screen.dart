import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/fitnet_user.dart';
import '../ui/fitnet_layout.dart';
import 'exercise_post_detail_screen.dart';
import 'space/space_screen.dart';

/// Xếp hạng bài đăng bài tập theo số vote (rating_count).
class ExerciseRankingCostScreen extends StatefulWidget {
  const ExerciseRankingCostScreen({
    super.key,
    required this.api,
    required this.me,
  });

  final ApiClient api;
  final FitnetUser me;

  @override
  State<ExerciseRankingCostScreen> createState() => _ExerciseRankingCostScreenState();
}

class _ExerciseRankingCostScreenState extends State<ExerciseRankingCostScreen> {
  bool _loading = true;
  String? _error;
  String _period = 'week';
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _exerciseVoteSubtitle(Map<String, dynamic> r) {
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
      final json = await widget.api.getJson('/api/leaderboards/exercise-posts/votes?period=$_period');
      final data = json['data'];
      final list = (data is List) ? data.cast<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
      setState(() => _rows = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _periodDropdown(bool compact, bool enabled) {
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
      items: const [
        DropdownMenuItem(value: 'day', child: Text('Hôm nay')),
        DropdownMenuItem(value: 'week', child: Text('Tuần này')),
        DropdownMenuItem(value: 'month', child: Text('Tháng này')),
        DropdownMenuItem(value: 'all', child: Text('Mọi thời điểm')),
      ],
    );
  }

  Widget _rankRow(ThemeData theme, Map<String, dynamic> r, bool compact) {
    final postId = int.tryParse(r['post_id']?.toString() ?? '') ?? 0;
    final title = (r['title'] ?? 'Unknown').toString();
    final votes = r['rating_count'] ?? 0;
    final rank = '${r['rank'] ?? ''}';

    void onTap() {
      if (postId <= 0) return;
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ExercisePostDetailScreen(api: widget.api, postId: postId),
        ),
      );
    }

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

    if (!compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: avatar,
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_exerciseVoteSubtitle(r)),
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
                          _exerciseVoteSubtitle(r),
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
        final pad = FitnetBreakpoints.pagePaddingInsets(c.maxWidth);

        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F5),
          appBar: AppBar(
            title: const Text('Ranking bài tập (theo vote)'),
            actions: [
              if (!compact)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DropdownButton<String>(
                    value: _period,
                    underline: const SizedBox.shrink(),
                    onChanged: _loading
                        ? null
                        : (v) {
                            if (v == null) return;
                            setState(() => _period = v);
                            _load();
                          },
                    items: const [
                      DropdownMenuItem(value: 'day', child: Text('Today')),
                      DropdownMenuItem(value: 'week', child: Text('This week')),
                      DropdownMenuItem(value: 'month', child: Text('This month')),
                      DropdownMenuItem(value: 'all', child: Text('All time')),
                    ],
                  ),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: pad,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (compact) ...[
                  Text(
                    'Khoảng thời gian',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      isDense: true,
                    ),
                    child: _periodDropdown(true, !_loading),
                  ),
                  const SizedBox(height: 12),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vote score',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Xếp hạng bài đăng bài tập theo số lượt vote (cao hơn = top).',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                      'Chưa có dữ liệu. Hãy đăng bài tập và vote sao để lên bảng xếp hạng.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => SpaceScreen(api: widget.api, me: widget.me),
                      ),
                    );
                  },
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Space — người cùng phòng'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
