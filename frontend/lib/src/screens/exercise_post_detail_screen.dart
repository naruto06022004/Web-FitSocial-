import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../ui/fitnet_layout.dart';

class ExercisePostDetailScreen extends StatefulWidget {
  const ExercisePostDetailScreen({
    super.key,
    required this.api,
    required this.postId,
  });

  final ApiClient api;
  final int postId;

  @override
  State<ExercisePostDetailScreen> createState() => _ExercisePostDetailScreenState();
}

class _ExercisePostDetailScreenState extends State<ExercisePostDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _comments = const [];

  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final postJson = await widget.api.getJson('/api/posts/${widget.postId}');
      final postData = postJson['data'];
      if (postData is! Map) {
        throw const FormatException('Missing data');
      }

      final commentsJson = await widget.api.getJson('/api/posts/${widget.postId}/comments');
      final cData = commentsJson['data'];
      final list = (cData is List) ? cData.cast<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];

      setState(() {
        _post = postData.cast<String, dynamic>();
        _comments = list;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rate(int stars) async {
    try {
      await widget.api.postJson('/api/posts/${widget.postId}/rating', {'stars': stars});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã vote $stars sao')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vote failed: $e')));
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await widget.api.postJson('/api/posts/${widget.postId}/comments', {'body': text});
      _commentCtrl.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gửi comment failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bài tập')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final p = _post ?? const <String, dynamic>{};
    final title = (p['title'] ?? '').toString();
    final content = (p['content'] ?? '').toString();
    final ratingAvg = (p['rating_avg'] is num) ? (p['rating_avg'] as num).toDouble() : double.tryParse(p['rating_avg']?.toString() ?? '');
    final ratingCount = int.tryParse(p['rating_count']?.toString() ?? '') ?? 0;

    final ex = p['exercise'];
    final exMap = (ex is Map) ? ex.cast<String, dynamic>() : null;

    final w = MediaQuery.sizeOf(context).width;
    return ListView(
      padding: FitnetBreakpoints.pagePaddingInsets(w),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                if (content.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(content),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Chip(label: Text(ratingAvg == null ? '$ratingCount vote' : '${ratingAvg.toStringAsFixed(1)} ★  ($ratingCount vote)')),
                    if (exMap != null) ...[
                      Chip(label: Text('Bài: ${exMap['name'] ?? ''}')),
                      Chip(label: Text('Type: ${exMap['type'] ?? ''}')),
                      Chip(label: Text('Độ khó: ${exMap['difficulty'] ?? ''}')),
                      if (exMap['met'] != null) Chip(label: Text('MET: ${exMap['met']}')),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, c) {
                    final stars = [
                      for (final s in [1, 2, 3, 4, 5])
                        IconButton(
                          tooltip: '$s sao',
                          onPressed: () => _rate(s),
                          icon: const Icon(Icons.star, size: 22),
                          style: IconButton.styleFrom(
                            foregroundColor: const Color(0xFFF59E0B),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ];
                    if (c.maxWidth < 360) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vote:', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900)),
                          Wrap(spacing: 0, runSpacing: 0, children: stars),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Text('Vote:', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(width: 8),
                        ...stars,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Bình luận', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final c in _comments) ...[
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.mode_comment_outlined, size: 18),
                    title: Text((c['body'] ?? '').toString()),
                    subtitle: Text('User #${c['user_id'] ?? ''}'),
                  ),
                  Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                ],
                if (_comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Chưa có bình luận'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, c) {
            final field = TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Nhập bình luận',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendComment(),
            );
            if (c.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field,
                  const SizedBox(height: 10),
                  FilledButton(onPressed: _sendComment, child: const Text('Gửi')),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: field),
                const SizedBox(width: 10),
                FilledButton(onPressed: _sendComment, child: const Text('Gửi')),
              ],
            );
          },
        ),
      ],
    );
  }
}

