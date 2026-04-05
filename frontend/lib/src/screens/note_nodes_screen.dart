import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NodeKind { text, image, video }

class FitnetNode {
  FitnetNode({
    required this.id,
    required this.kind,
    required this.title,
    required this.note,
    this.link,
    required this.createdAt,
  });

  final String id;
  final NodeKind kind;
  final String title;
  final String note;
  final String? link;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'note': note,
        'link': link,
        'createdAt': createdAt.toIso8601String(),
      };

  static FitnetNode fromJson(Map<String, dynamic> j) {
    return FitnetNode(
      id: j['id']?.toString() ?? '',
      kind: NodeKind.values.firstWhere(
        (e) => e.name == j['kind'],
        orElse: () => NodeKind.text,
      ),
      title: j['title']?.toString() ?? '',
      note: j['note']?.toString() ?? '',
      link: j['link']?.toString(),
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Giao diện "node" — ghi chú video / ảnh / chữ (lưu máy).
class NoteNodesScreen extends StatefulWidget {
  const NoteNodesScreen({super.key});

  @override
  State<NoteNodesScreen> createState() => _NoteNodesScreenState();
}

class _NoteNodesScreenState extends State<NoteNodesScreen> {
  static const _storageKey = 'fitnet_note_nodes';
  List<FitnetNode> _nodes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      setState(() {
        _nodes = [];
        _loading = false;
      });
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      setState(() {
        _nodes = list.map((e) => FitnetNode.fromJson((e as Map).cast<String, dynamic>())).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _nodes = [];
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_nodes.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  Future<void> _addNode() async {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    NodeKind kind = NodeKind.text;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              title: const Text('Node mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<NodeKind>(
                      segments: const [
                        ButtonSegment(value: NodeKind.text, label: Text('Chữ'), icon: Icon(Icons.notes)),
                        ButtonSegment(value: NodeKind.image, label: Text('Ảnh'), icon: Icon(Icons.image_outlined)),
                        ButtonSegment(value: NodeKind.video, label: Text('Video'), icon: Icon(Icons.play_circle_outline)),
                      ],
                      selected: {kind},
                      onSelectionChanged: (s) => setDialog(() => kind = s.first),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder()),
                      minLines: 2,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: linkCtrl,
                      decoration: InputDecoration(
                        labelText: kind == NodeKind.video
                            ? 'Link video (YouTube, …)'
                            : kind == NodeKind.image
                                ? 'Link ảnh (URL)'
                                : 'Link tham khảo (tuỳ chọn)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu node')),
              ],
            );
          },
        );
      },
    );

    if (ok != true) {
      titleCtrl.dispose();
      noteCtrl.dispose();
      linkCtrl.dispose();
      return;
    }
    if (!mounted) {
      titleCtrl.dispose();
      noteCtrl.dispose();
      linkCtrl.dispose();
      return;
    }

    final title = titleCtrl.text.trim();
    final note = noteCtrl.text.trim();
    final linkRaw = linkCtrl.text.trim();
    titleCtrl.dispose();
    noteCtrl.dispose();
    linkCtrl.dispose();

    if (title.isEmpty) return;

    final node = FitnetNode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      kind: kind,
      title: title,
      note: note,
      link: linkRaw.isEmpty ? null : linkRaw,
      createdAt: DateTime.now(),
    );

    setState(() => _nodes = [node, ..._nodes]);
    await _save();
  }

  Future<void> _delete(FitnetNode n) async {
    setState(() => _nodes = _nodes.where((e) => e.id != n.id).toList());
    await _save();
  }

  IconData _iconFor(NodeKind k) {
    switch (k) {
      case NodeKind.text:
        return Icons.notes;
      case NodeKind.image:
        return Icons.image_outlined;
      case NodeKind.video:
        return Icons.play_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Node — ghi chú học tập'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNode,
        icon: const Icon(Icons.add),
        label: const Text('Thêm node'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _nodes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Chưa có node. Thêm video, ảnh hoặc ghi chú chữ để ôn lại sau.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _nodes.length,
                  itemBuilder: (context, i) {
                    final n = _nodes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(_iconFor(n.kind)),
                        ),
                        title: Text(n.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (n.note.isNotEmpty) Text(n.note, maxLines: 3, overflow: TextOverflow.ellipsis),
                            if (n.link != null)
                              Text(
                                n.link!,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              '${n.createdAt.year}-${n.createdAt.month.toString().padLeft(2, '0')}-${n.createdAt.day.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(n),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
