class ChatUserSummary {
  const ChatUserSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final String role;

  factory ChatUserSummary.fromJson(Map<String, dynamic> json) {
    return ChatUserSummary(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.body,
    this.createdAt,
    this.readAt,
    this.senderName,
    this.recipientName,
  });

  final int id;
  final int senderId;
  final int recipientId;
  final String body;
  final DateTime? createdAt;
  final DateTime? readAt;
  final String? senderName;
  final String? recipientName;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final recipient = json['recipient'];
    return ChatMessage(
      id: (json['id'] as num).toInt(),
      senderId: (json['sender_id'] as num).toInt(),
      recipientId: (json['recipient_id'] as num).toInt(),
      body: json['body']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      senderName: sender is Map<String, dynamic> ? sender['name']?.toString() : null,
      recipientName: recipient is Map<String, dynamic> ? recipient['name']?.toString() : null,
    );
  }
}

class ConversationPreview {
  const ConversationPreview({
    required this.peer,
    required this.unreadCount,
    this.lastBody,
    this.lastAt,
  });

  final ChatUserSummary peer;
  final int unreadCount;
  final String? lastBody;
  final DateTime? lastAt;

  factory ConversationPreview.fromJson(Map<String, dynamic> json) {
    final peer = ChatUserSummary.fromJson(json['peer'] as Map<String, dynamic>);
    final last = json['last_message'];
    String? body;
    DateTime? at;
    if (last is Map<String, dynamic>) {
      body = last['body']?.toString();
      at = last['created_at'] != null ? DateTime.tryParse(last['created_at'].toString()) : null;
    }
    return ConversationPreview(
      peer: peer,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      lastBody: body,
      lastAt: at,
    );
  }
}

