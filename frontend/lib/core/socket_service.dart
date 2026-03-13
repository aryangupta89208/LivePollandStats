import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

class SocketService {
  static SocketService? _instance;
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  Timer? _reconnectTimer;
  bool _isConnected = false;

  factory SocketService() {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  SocketService._internal();

  Stream<Map<String, dynamic>> get stream =>
      _controller?.stream ?? const Stream.empty();

  bool get isConnected => _isConnected;

  void connect() {
    if (_isConnected) return;

    _controller?.close();
    _controller = StreamController<Map<String, dynamic>>.broadcast();

    final wsUrl = ApiService.baseUrl.replaceFirst('http', 'ws');
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws'));
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String);
            _controller?.add(decoded);
          } catch (_) {}
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void subscribeToPoll(String pollId) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode({
        'type': 'subscribe',
        'poll_id': pollId,
      }));
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller?.close();
    _isConnected = false;
  }
}
