import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../ui/fitnet_layout.dart';

class AdminExercisesScreen extends StatefulWidget {
  const AdminExercisesScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<AdminExercisesScreen> createState() => _AdminExercisesScreenState();
}

class _AdminExercisesScreenState extends State<AdminExercisesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  bool? _approvedFilter; // null = all
  String _search = '';

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
      final qs = <String, String>{};
      final approved = _approvedFilter;
      if (approved != null) qs['approved'] = approved.toString();
      if (_search.trim().isNotEmpty) qs['search'] = _search.trim();

      final path = qs.isEmpty
          ? '/api/admin/exercises'
          : '/api/admin/exercises?${qs.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&')}';

      final json = await widget.api.getJson(path);
      final data = json['data'];
      final list = (data is List) ? data.cast<Map>().map((e) => e.cast<String, dynamic>()).toList() : <Map<String, dynamic>>[];
      setState(() => _items = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> ex) async {
    final nameCtrl = TextEditingController(text: (ex['name'] ?? '').toString());
    final typeCtrl = TextEditingController(text: (ex['type'] ?? '').toString());
    final diffCtrl = TextEditingController(text: (ex['difficulty'] ?? 2).toString());
    final metCtrl = TextEditingController(text: (ex['met'] ?? '').toString());
    final coeffCtrl = TextEditingController(text: (ex['coeff'] ?? 1.0).toString());

    bool approved = (ex['is_approved'] ?? false) == true;

    final result = await showDialog<Object>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Edit exercise'),
          content: SizedBox(
            width: (MediaQuery.sizeOf(context).width - 48).clamp(280.0, 520),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(labelText: 'Type (strength/cardio/hiit/bodyweight)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: diffCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Difficulty (1..5)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: metCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'MET (cardio/hiit)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: coeffCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Coeff (strength multiplier)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: approved,
                    onChanged: (v) => setStateDialog(() => approved = v),
                    title: const Text('Approved'),
                    subtitle: const Text('Exercise must be approved to appear in user list'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            TextButton(
              onPressed: () => Navigator.pop(context, 'delete'),
              child: Text('Xóa bài tập', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700)),
            ),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );

    if (result == 'delete') {
      await _delete(ex);
      return;
    }
    if (result != true) return;

    num? parseNum(String s) {
      final t = s.trim();
      if (t.isEmpty) return null;
      return num.tryParse(t);
    }

    final payload = <String, dynamic>{
      'name': nameCtrl.text.trim(),
      'type': typeCtrl.text.trim(),
      'difficulty': int.tryParse(diffCtrl.text.trim()) ?? 2,
      'met': parseNum(metCtrl.text),
      'coeff': (parseNum(coeffCtrl.text) ?? 1.0),
      'is_approved': approved,
    };

    try {
      await widget.api.putJson('/api/admin/exercises/${ex['id']}', payload);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _delete(Map<String, dynamic> ex) async {
    final posts = int.tryParse(ex['posts_count']?.toString() ?? '') ?? 0;
    final extra = posts > 0
        ? ' $posts bài post bài tập vẫn giữ nhưng sẽ mất liên kết exercise (nullOnDelete).'
        : '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài tập?'),
        content: Text('Sẽ xóa "${ex['name']}". Rating & workout log liên quan cũng bị xóa.$extra'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.deleteJson('/api/admin/exercises/${ex['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bài tập')));
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
    }
  }

  Widget _errorRow(ThemeData theme, bool compact) {
    if (compact) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_error!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
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

  Widget _exerciseTile(ThemeData theme, Map<String, dynamic> ex, bool compact) {
    final subtitle =
        'type: ${ex['type']}  • diff: ${ex['difficulty']}  • met: ${ex['met'] ?? '-'}  • coeff: ${ex['coeff'] ?? '-'}'
        '  • rating: ${(ex['rating_avg'] ?? '-')} (${ex['rating_count'] ?? 0})'
        '  • posts: ${ex['posts_count'] ?? 0}';

    final menu = PopupMenuButton<String>(
      tooltip: 'Thêm',
      onSelected: (v) {
        if (v == 'edit') _edit(ex);
        if (v == 'delete') _delete(ex);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
        PopupMenuItem(value: 'delete', child: Text('Xóa…')),
      ],
    );

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _edit(ex),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon((ex['is_approved'] == true) ? Icons.verified_outlined : Icons.hourglass_empty_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (ex['name'] ?? '').toString(),
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Xóa bài tập',
                                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                onPressed: _loading ? null : () => _delete(ex),
                              ),
                              menu,
                            ],
                          ),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon((ex['is_approved'] == true) ? Icons.verified_outlined : Icons.hourglass_empty_outlined),
          title: Text((ex['name'] ?? '').toString()),
          subtitle: Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Xóa bài tập',
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                onPressed: _loading ? null : () => _delete(ex),
              ),
              menu,
            ],
          ),
        ),
        Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        final compact = FitnetBreakpoints.isCompactWidth(c.maxWidth);
        final pad = FitnetBreakpoints.pagePaddingInsets(c.maxWidth);

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: pad,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Exercise Management', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Reload',
                        onPressed: _loading ? null : _load,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text('Exercise Management', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    ),
                    IconButton(
                      tooltip: 'Reload',
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                labelText: 'Search',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) => _search = v,
                              onSubmitted: (_) => _load(),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<bool?>(
                              key: ValueKey(_approvedFilter),
                              initialValue: _approvedFilter,
                              decoration: const InputDecoration(
                                labelText: 'Trạng thái duyệt',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              isExpanded: true,
                              onChanged: (v) => setState(() => _approvedFilter = v),
                              items: const [
                                DropdownMenuItem(value: null, child: Text('All')),
                                DropdownMenuItem(value: true, child: Text('Approved')),
                                DropdownMenuItem(value: false, child: Text('Pending')),
                              ],
                            ),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              onPressed: _loading ? null : _load,
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('Apply'),
                            ),
                          ],
                        )
                      : Wrap(
                          runSpacing: 10,
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: 280,
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Search',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (v) => _search = v,
                                onSubmitted: (_) => _load(),
                              ),
                            ),
                            DropdownButton<bool?>(
                              value: _approvedFilter,
                              onChanged: (v) => setState(() => _approvedFilter = v),
                              items: const [
                                DropdownMenuItem(value: null, child: Text('All')),
                                DropdownMenuItem(value: true, child: Text('Approved')),
                                DropdownMenuItem(value: false, child: Text('Pending')),
                              ],
                            ),
                            FilledButton.icon(
                              onPressed: _loading ? null : _load,
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('Apply'),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              if (!_loading && _error != null) _errorRow(theme, compact),
              if (!_loading && _error == null && _items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chưa có bài tập trong hệ thống', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                          'Khi người dùng đăng bài dạng «Bài tập» (tạo bài tập mới hoặc chọn bài có sẵn), bản ghi sẽ xuất hiện ở đây — kể cả chưa duyệt. '
                          'Nếu bạn vừa đăng mà không thấy: bấm làm mới hoặc đăng xuất rồi đăng nhập lại bằng tài khoản admin/staff.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_loading && _error == null && _items.isNotEmpty)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final ex in _items) _exerciseTile(theme, ex, compact),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
