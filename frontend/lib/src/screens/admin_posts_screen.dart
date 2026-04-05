import 'package:flutter/material.dart';

import '../api/api_client.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
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
            width: 420,
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 10),
            FilledButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Text('Posts', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: Text('Chưa có post nào')),
            ),
          for (final p in _items)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['title']?.toString() ?? '(no title)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(p['content']?.toString() ?? ''),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('id: ${p['id']} • user_id: ${p['user_id']}'),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => _editPost(p),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => _deletePost(p),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

