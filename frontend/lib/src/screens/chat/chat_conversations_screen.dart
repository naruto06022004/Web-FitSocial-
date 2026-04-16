import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../models/fitnet_user.dart';
import 'chat_models.dart';
import 'chat_thread_screen.dart';
import 'chat_user_search_screen.dart';

/// Nội dung danh sách hội thoại (dùng trong [FitnetChrome], không có AppBar riêng).
class ChatConversationsScreen extends StatefulWidget {
  const ChatConversationsScreen({
    super.key,
    required this.api,
    required this.me,
    required this.pushChrome,
    required this.replaceChrome,
  });

  final ApiClient api;
  final FitnetUser me;
  final void Function(BuildContext navigatorContext, Widget page) pushChrome;
  final void Function(BuildContext navigatorContext, Widget page) replaceChrome;

  @override
  State<ChatConversationsScreen> createState() => _ChatConversationsScreenState();
}

class _ChatConversationsScreenState extends State<ChatConversationsScreen> {
  bool _loading = true;
  String? _error;
  List<ConversationPreview> _items = const [];

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
      final json = await widget.api.getJson('/api/chat/conversations');
      final data = json['data'];
      final list = <ConversationPreview>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            list.add(ConversationPreview.fromJson(item.cast<String, dynamic>()));
          }
        }
      }
      setState(() => _items = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
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
                            FilledButton(onPressed: _load, child: const Text('Thử lại')),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                        itemCount: _items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final c = _items[i];
                          final unread = c.unreadCount > 0;
                          return Card(
                            child: ListTile(
                              title: Text(
                                c.peer.name,
                                style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600),
                              ),
                              subtitle: Text(
                                [
                                  c.peer.email,
                                  if ((c.lastBody ?? '').isNotEmpty) c.lastBody!,
                                ].join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: unread
                                  ? CircleAvatar(
                                      radius: 12,
                                      backgroundColor: const Color(0xFF1877F2),
                                      foregroundColor: Colors.white,
                                      child: Text('${c.unreadCount}', style: const TextStyle(fontSize: 11)),
                                    )
                                  : null,
                              onTap: () async {
                                widget.pushChrome(
                                  context,
                                  ChatThreadScreen(api: widget.api, me: widget.me, peer: c.peer),
                                );
                                await _load();
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () async {
              widget.pushChrome(
                context,
                ChatUserSearchScreen(
                  api: widget.api,
                  me: widget.me,
                  replaceChrome: widget.replaceChrome,
                ),
              );
              await _load();
            },
            child: const Icon(Icons.edit_outlined),
          ),
        ),
      ],
    );
  }
}
