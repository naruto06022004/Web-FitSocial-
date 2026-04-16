import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../models/fitnet_user.dart';
import 'space_storage.dart';

class SpacePeer {
  const SpacePeer({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final String role;

  factory SpacePeer.fromJson(Map<String, dynamic> json) {
    return SpacePeer(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
    );
  }
}

class SpaceScreen extends StatefulWidget {
  const SpaceScreen({
    super.key,
    required this.api,
    required this.me,
  });

  final ApiClient api;
  final FitnetUser me;

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> {
  bool _loading = true;
  String? _error;
  List<SpacePeer> _peers = const [];
  Set<int> _saved = <int>{};
  SpaceStorage? _storage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await SpaceStorage.create();
    setState(() {
      _storage = storage;
      _saved = storage.readSavedPeerIds();
    });
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await widget.api.getJson('/api/training-space/peers');
      final data = json['data'];
      final list = <SpacePeer>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map) list.add(SpacePeer.fromJson(item.cast<String, dynamic>()));
        }
      }
      setState(() => _peers = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSaved(int userId) async {
    final storage = _storage;
    if (storage == null) return;
    final next = Set<int>.from(_saved);
    if (next.contains(userId)) {
      next.remove(userId);
    } else {
      next.add(userId);
    }
    setState(() => _saved = next);
    await storage.writeSavedPeerIds(next);
  }

  @override
  Widget build(BuildContext context) {
    final savedFirst = [
      ..._peers.where((p) => _saved.contains(p.id)),
      ..._peers.where((p) => !_saved.contains(p.id)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(title: const Text('Space')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Những người cùng “phòng”', style: TextStyle(fontWeight: FontWeight.w800)),
                              SizedBox(height: 6),
                              Text('Danh sách lấy từ API: /api/training-space/peers. Bạn có thể “lưu” để ghim lên đầu.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final p in savedFirst)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text((p.name.isNotEmpty ? p.name[0] : '?').toUpperCase()),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${p.email} · ${p.role}'),
                            trailing: IconButton(
                              tooltip: 'Lưu',
                              icon: Icon(_saved.contains(p.id) ? Icons.bookmark : Icons.bookmark_outline),
                              onPressed: () => _toggleSaved(p.id),
                            ),
                          ),
                        ),
                      if (savedFirst.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('Chưa có peer nào')),
                        ),
                    ],
                  ),
                ),
    );
  }
}

