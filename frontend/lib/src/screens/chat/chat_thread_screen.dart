import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../models/fitnet_user.dart';
import 'chat_models.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.api,
    required this.me,
    required this.peer,
  });

  final ApiClient api;
  final FitnetUser me;
  final ChatUserSummary peer;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();

  bool _loading = true;
  bool _sending = false;
  bool _loadingMore = false;
  String? _error;

  List<ChatMessage> _messages = const [];
  int _page = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _load(markSeen: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _load({required bool markSeen, bool older = false}) async {
    if (older) {
      if (_loadingMore || _page >= _lastPage) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final nextPage = older ? _page + 1 : 1;
      final qs = [
        'with_user_id=${widget.peer.id}',
        'page=$nextPage',
        if (markSeen && !older) 'mark_seen=1',
      ].join('&');
      final json = await widget.api.getJson('/api/chat/messages?$qs');
      final data = json['data'];
      final meta = json['meta'];

      final list = <ChatMessage>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map) list.add(ChatMessage.fromJson(item.cast<String, dynamic>()));
        }
      }
      list.sort((a, b) => a.id.compareTo(b.id));

      final lp = meta is Map ? int.tryParse(meta['last_page']?.toString() ?? '1') ?? 1 : 1;

      setState(() {
        _lastPage = lp;
        if (older) {
          _page = nextPage;
          final merged = [...list, ..._messages];
          final byId = {for (final m in merged) m.id: m};
          _messages = byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
        } else {
          _page = 1;
          _messages = list;
        }
      });

      if (!older) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.api.postJson('/api/chat/messages', {
        'recipient_id': widget.peer.id,
        'body': text,
      });
      _input.clear();
      await _load(markSeen: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF0F2F5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.peer.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (_loadingMore) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _loading
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
                              FilledButton(
                                onPressed: () => _load(markSeen: false),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        children: [
                          if (_page < _lastPage)
                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: _loadingMore ? null : () => _load(markSeen: false, older: true),
                                child: const Text('Tải tin cũ hơn'),
                              ),
                            ),
                          ..._messages.map((m) {
                            final mine = m.senderId == widget.me.id;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 520),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: mine ? const Color(0xFF1877F2) : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      m.body,
                                      style: TextStyle(color: mine ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn…',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
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
