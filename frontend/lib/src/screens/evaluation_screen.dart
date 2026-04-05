import 'package:flutter/material.dart';

import '../api/api_client.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _posts = const [];

  final Map<int, int> _voteSum = <int, int>{};
  final Map<int, int> _voteCount = <int, int>{};

  @override
  void initState() {
    super.initState();
    _loadPosts();
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
      setState(() => _posts = list);
    } catch (_) {
      setState(() => _error = 'Không tải được bài tập');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _avg(int postId) {
    final c = _voteCount[postId] ?? 0;
    if (c == 0) return 0;
    return (_voteSum[postId] ?? 0) / c;
  }

  Widget _stars(double avg) {
    final filled = avg.round().clamp(0, 5);
    return Row(
      children: List.generate(5, (i) {
        final on = i < filled;
        return Icon(
          on ? Icons.star : Icons.star_border,
          size: 18,
          color: on ? Colors.amber : null,
        );
      }),
    );
  }

  Future<void> _ratePost(int postId) async {
    int selected = 5;
    final commentCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Đánh giá bài tập'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _stars(selected.toDouble()),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (i) {
                        final value = i + 1;
                        final active = value == selected;
                        return IconButton(
                          icon: Icon(
                            active ? Icons.star : Icons.star_border,
                            color: active ? Colors.amber : null,
                          ),
                          onPressed: () => setStateDialog(() => selected = value),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (demo)',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _voteSum[postId] = (_voteSum[postId] ?? 0) + selected;
                      _voteCount[postId] = (_voteCount[postId] ?? 0) + 1;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Gửi đánh giá'),
                ),
              ],
            );
          },
        );
      },
    );

    commentCtrl.dispose();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đánh giá bài tập')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              const SizedBox(height: 10),
              FilledButton(onPressed: _loadPosts, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá bài tập')),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_posts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text('Chưa có bài tập')),
              ),
            for (final p in _posts) ...[
              Builder(builder: (context) {
                final id = int.tryParse(p['id']?.toString() ?? '') ?? -1;
                if (id < 0) return const SizedBox.shrink();
                final avg = _avg(id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['title']?.toString() ?? '(no title)', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _stars(avg),
                        const SizedBox(height: 8),
                        Text('Điểm TB: ${avg.toStringAsFixed(1)}'),
                        const SizedBox(height: 8),
                        Text(p['content']?.toString() ?? ''),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => _ratePost(id),
                            icon: const Icon(Icons.rate_review_outlined),
                            label: const Text('Đánh giá'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

