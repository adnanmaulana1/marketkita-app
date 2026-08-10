import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../services/api.dart';
import '../services/ws_service.dart';
import '../state/app_state.dart';
import '../utils/format.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final ChatUser peer;
  const ChatScreen({super.key, required this.conversationId, required this.peer});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _ws = WsService.instance;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _peerTyping = false;
  late int _myId;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    _myId = context.read<AppState>().user?.id ?? 0;
    _ws.connect();
    _load();
    _ws.listen(_onWsEvent);
    _ws.sendOpen(widget.conversationId);
  }

  @override
  void dispose() {
    _ws.removeAll(_onWsEvent);
    _typingDebounce?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Api.chatMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = r.messages;
        _loading = false;
      });
      Api.chatMarkRead(widget.conversationId);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _onWsEvent(Map<String, dynamic> data) {
    if (!mounted) return;
    final type = data['type']?.toString();
    switch (type) {
      case 'message':
        final m = data['message'];
        if (m is Map) {
          final msg = ChatMessage.fromJson(Map<String, dynamic>.from(m));
          if (msg.conversationId == widget.conversationId) {
            setState(() => _messages.add(msg));
            _scrollToBottom();
          }
        }
        break;
      case 'typing':
        if ((data['conversation_id'] as num?)?.toInt() == widget.conversationId &&
            (data['user_id'] as num?)?.toInt() != _myId) {
          setState(() => _peerTyping = data['is_typing'] == true);
        }
        break;
      case 'read':
        if ((data['conversation_id'] as num?)?.toInt() == widget.conversationId) {
          setState(() {
            _messages = _messages.map((m) {
              if (m.senderId == _myId && !m.isRead) {
                return ChatMessage(
                  id: m.id,
                  conversationId: m.conversationId,
                  senderId: m.senderId,
                  body: m.body,
                  isRead: true,
                  createdAt: m.createdAt,
                );
              }
              return m;
            }).toList();
          });
        }
        break;
    }
  }

  void _send() {
    final body = _input.text.trim();
    if (body.isEmpty) return;
    _ws.sendMessage(widget.conversationId, body);
    _input.clear();
  }

  void _onTypingChanged(String _) {
    _typingDebounce?.cancel();
    _ws.sendTyping(widget.conversationId, true);
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      _ws.sendTyping(widget.conversationId, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final meId = _myId;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(widget.peer.role == 'toko' ? Icons.storefront : widget.peer.role == 'kurir' ? Icons.two_wheeler : Icons.person, size: 18, color: Colors.grey[700]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.peer.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (_peerTyping)
                    const Text('mengetik...', style: TextStyle(fontSize: 11, color: Colors.green, fontStyle: FontStyle.italic))
                  else
                    Text(widget.peer.role, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Belum ada pesan. Sapalah!', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _Bubble(msg: _messages[i], isMe: _messages[i].senderId == meId, meId: meId),
                      ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onChanged: _onTypingChanged,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF171717), foregroundColor: Colors.white),
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

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final int meId;
  const _Bubble({required this.msg, required this.isMe, required this.meId});

  @override
  Widget build(BuildContext context) {
    final mine = msg.senderId == meId;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFF171717) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg.body, style: TextStyle(color: mine ? Colors.white : Colors.black87, height: 1.4)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatDate(msg.createdAt), style: TextStyle(fontSize: 10, color: mine ? Colors.white54 : Colors.grey[500])),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(msg.isRead ? Icons.done_all : Icons.done, size: 14, color: msg.isRead ? Colors.lightBlueAccent : Colors.white54),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
