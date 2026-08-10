class ChatUser {
  final int id;
  final String nama;
  final String email;
  final String role;
  final String foto;
  final String? storeSlug;

  ChatUser({
    required this.id,
    required this.nama,
    this.email = '',
    this.role = 'pembeli',
    this.foto = '',
    this.storeSlug,
  });

  factory ChatUser.fromJson(Map<String, dynamic> j) => ChatUser(
        id: (j['id'] as num?)?.toInt() ?? 0,
        nama: j['nama'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'pembeli',
        foto: j['foto'] as String? ?? '',
        storeSlug: j['store_slug'] as String?,
      );
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String body;
  final bool isRead;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.isRead = false,
    this.createdAt = '',
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: (j['id'] as num?)?.toInt() ?? 0,
        conversationId: (j['conversation_id'] as num?)?.toInt() ?? 0,
        senderId: (j['sender_id'] as num?)?.toInt() ?? 0,
        body: j['body'] as String? ?? '',
        isRead: j['is_read'] as bool? ?? false,
        createdAt: j['created_at'] as String? ?? '',
      );
}

class Conversation {
  final int id;
  final ChatUser peer;
  final String lastBody;
  final String lastCreatedAt;
  final int? lastSenderId;
  final bool? lastIsRead;
  final int unread;
  final String updatedAt;

  Conversation({
    required this.id,
    required this.peer,
    this.lastBody = '',
    this.lastCreatedAt = '',
    this.lastSenderId,
    this.lastIsRead,
    this.unread = 0,
    this.updatedAt = '',
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: (j['id'] as num?)?.toInt() ?? 0,
        peer: ChatUser.fromJson((j['peer'] as Map?)?.cast<String, dynamic>() ?? {}),
        lastBody: j['last']?['body'] as String? ?? '',
        lastCreatedAt: j['last']?['created_at'] as String? ?? '',
        lastSenderId: (j['last']?['sender_id'] as num?)?.toInt(),
        lastIsRead: j['last']?['is_read'] as bool?,
        unread: (j['unread'] as num?)?.toInt() ?? 0,
        updatedAt: j['updated_at'] as String? ?? '',
      );
}
