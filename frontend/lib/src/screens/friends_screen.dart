import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _q = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = const [];

  @override
  void initState() {
    super.initState();
    _q.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 280), _load);
    });
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = Uri.encodeQueryComponent(_q.text.trim());
      final path = query.isEmpty ? '/api/friends' : '/api/friends?q=$query';
      final json = await widget.api.getJson(path);
      final data = json['data'];
      final list = <Map<String, dynamic>>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            list.add(Map<String, dynamic>.from(item.cast<String, dynamic>()));
          }
        }
      }
      setState(() => _users = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: const Color(0xFFF0F2F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Bạn bè & gợi ý',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _q,
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên hoặc email…',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading && _users.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Center(child: FilledButton(onPressed: _load, child: const Text('Thử lại'))),
                          ],
                        )
                      : _users.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: [
                                Icon(Icons.people_outline, size: 48, color: theme.colorScheme.outline),
                                const SizedBox(height: 12),
                                Text(
                                  'Chưa có gợi ý nào. Thử tìm kiếm khác.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                              itemCount: _users.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final u = _users[i];
                                final name = u['name']?.toString() ?? '—';
                                final email = u['email']?.toString() ?? '';
                                final gym = u['gym_name']?.toString();
                                return Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Text(
                                      [
                                        email,
                                        if (gym != null && gym.isNotEmpty) gym,
                                      ].where((s) => s.isNotEmpty).join(' · '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Icon(Icons.person_add_alt_1_outlined, color: theme.colorScheme.primary),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
