import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/api.dart';
import '../utils/format.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Conversation>? _conversations;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final convs = await Api.chatConversations();
      if (mounted) setState(() => _conversations = convs);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startNewChat() async {
    List<ChatUser> users;
    try {
      users = await Api.chatUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    if (!mounted) return;
    final sel = await showModalBottomSheet<ChatUser>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UserPicker(users: users),
    );
    if (sel == null) return;
    final convId = await Api.chatCreateConversation(sel.id);
    if (!mounted) return;
    await _open(convId, sel);
  }

  Future<void> _open(int convId, ChatUser peer) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(conversationId: convId, peer: peer),
    ));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesan', style: TextStyle(fontWeight: FontWeight.w800))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF171717),
        foregroundColor: Colors.white,
        onPressed: _startNewChat,
        child: const Icon(Icons.chat_outlined),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _conversations == null || _conversations!.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Center(child: Text('Belum ada percakapan')),
                        SizedBox(height: 6),
                        Center(child: Text('Mulai chat dengan pembeli, toko, atau kurir', style: TextStyle(color: Colors.grey))),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _conversations!.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
                      itemBuilder: (_, i) => _ConversationTile(
                        conv: _conversations![i],
                        onTap: () => _open(_conversations![i].id, _conversations![i].peer),
                      ),
                    ),
            ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conv;
  final VoidCallback onTap;
  const _ConversationTile({required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = conv.peer;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: p.foto.isEmpty
            ? Icon(_roleIcon(p.role), color: Colors.grey[700])
            : null,
      ),
      title: Text(p.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        conv.lastBody.isEmpty ? 'Belum ada pesan' : conv.lastBody,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: conv.unread > 0 ? Colors.black : Colors.grey[600], fontWeight: conv.unread > 0 ? FontWeight.w600 : FontWeight.w400),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatDate(conv.lastCreatedAt, withTime: false), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          if (conv.unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
              child: Text('${conv.unread}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'toko':
        return Icons.storefront;
      case 'kurir':
        return Icons.two_wheeler;
      default:
        return Icons.person;
    }
  }
}

class _UserPicker extends StatelessWidget {
  final List<ChatUser> users;
  const _UserPicker({required this.users});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Pilih Kontak', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: users.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
                itemBuilder: (_, i) {
                  final u = users[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(u.role == 'anda' ? Icons.person : _icon(u.role), color: Colors.grey[700]),
                    ),
                    title: Text(u.nama),
                    subtitle: Text(u.email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    onTap: () => Navigator.pop(context, u),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String role) {
    switch (role) {
      case 'toko':
        return Icons.storefront;
      case 'kurir':
        return Icons.two_wheeler;
      default:
        return Icons.person;
    }
  }
}
