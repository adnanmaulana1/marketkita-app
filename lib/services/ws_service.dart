import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';
import '../services/api.dart';

class WsService {
  static WsService? _instance;
  static WsService get instance => _instance ??= WsService._();

  WebSocketChannel? _channel;
  final _listeners = <void Function(Map<String, dynamic>)>[];
  final _handlers = <String, List<void Function(Map<String, dynamic>)>>{};
  Timer? _reconnectTimer;
  bool _disposed = false;

  WsService._();

  bool get isConnected => _channel != null;

  void listen(void Function(Map<String, dynamic>) cb) {
    _listeners.add(cb);
  }

  void on(String type, void Function(Map<String, dynamic>) cb) {
    _handlers.putIfAbsent(type, () => []).add(cb);
  }

  void removeAll(void Function(Map<String, dynamic>) cb) {
    _listeners.remove(cb);
    _handlers.forEach((_, list) => list.remove(cb));
  }

  void connect() {
    if (_disposed) return;
    final token = Api.token;
    if (token == null || _channel != null) return;
    final base = Uri.parse(AppConfig.baseUrl);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    final uri = Uri.parse('$wsScheme://${base.host}${base.port != 80 ? ':${base.port}' : ''}/ws/chat');
    try {
      _channel = IOWebSocketChannel.connect(uri, headers: {'Authorization': 'Bearer $token'});
      _channel!.stream.listen(_onData, onDone: _onDone, onError: (_) => _onDone());
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    try {
      final data = jsonDecode(raw.toString());
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      for (final cb in _listeners) {
        cb(m);
      }
      final type = data['type']?.toString();
      if (type != null && _handlers.containsKey(type)) {
        for (final cb in List.of(_handlers[type]!)) {
          cb(m);
        }
      }
    } catch (_) {}
  }

  void _onDone() {
    _channel = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _channel = null;
      connect();
    });
  }

  void send(Map<String, dynamic> data) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (_) {}
  }

  void sendMessage(int conversationId, String body) {
    send({'type': 'message', 'conversation_id': conversationId, 'body': body});
  }

  void sendTyping(int conversationId, bool isTyping) {
    send({'type': 'typing', 'conversation_id': conversationId, 'is_typing': isTyping});
  }

  void sendOpen(int conversationId) {
    send({'type': 'open', 'conversation_id': conversationId});
  }

  /// Keep-alive agar proxy/load balancer tidak menutup koneksi idle.
  void sendPing() {
    send({'type': 'ping'});
  }

  void sendLocation(List<int> orderIds, double lat, double lng) {
    send({'type': 'kurir_location', 'order_ids': orderIds, 'lat': lat, 'lng': lng});
  }

  /// Menutup koneksi saat ini tanpa mematikan singleton secara permanen,
  /// sehingga koneksi baru tetap bisa dibuka setelah login ulang.
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _listeners.clear();
    _handlers.clear();
  }
}
