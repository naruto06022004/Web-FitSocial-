import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../models/fitnet_user.dart';
import 'chat_models.dart';
import 'chat_thread_screen.dart';

typedef FitnetChromeReplace = void Function(BuildContext navigatorContext, Widget page);

class ChatUserSearchScreen extends StatefulWidget {
  const ChatUserSearchScreen({
    super.key,
    required this.api,
    required this.me,
    required this.replaceChrome,
  });

  final ApiClient api;
  final FitnetUser me;
  final FitnetChromeReplace replaceChrome;

  @override
  State<ChatUserSearchScreen> createState() => _ChatUserSearchScreenState();
}

class _ChatUserSearchScreenState extends State<ChatUserSearchScreen> {
  final TextEditingController _q = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<ChatUserSummary> _users = const [];

  @override
  void initState() {
    super.initState();
    _q.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), _search);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = Uri.encodeQueryComponent(_q.text.trim());
      final json = await widget.api.getJson('/api/chat/directory?q=$query');
      final data = json['data'];
      final list = <ChatUserSummary>[];
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            list.add(ChatUserSummary.fromJson(item.cast<String, dynamic>()));
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
    return ColoredBox(
      color: const Color(0xFFF0F2F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Tin nhắn mới',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _q,
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên hoặc email…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _users.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final u = _users[i];
                      return ListTile(
                        title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(u.email),
                        onTap: () {
                          widget.replaceChrome(
                            context,
                            ChatThreadScreen(api: widget.api, me: widget.me, peer: u),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
