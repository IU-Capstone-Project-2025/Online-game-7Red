import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';


// The basic class for handling WebSocket communication
class GameWebSocket {
  final String serverUrl;
  WebSocketChannel? _channel;
  final Function(dynamic) onMessageReceived;
  final Function onConnectionClosed;

  GameWebSocket({
    required this.serverUrl,
    required this.onMessageReceived,
    required this.onConnectionClosed,
  });

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    _channel!.stream.listen(
      (message) {
        onMessageReceived(json.decode(message));
      },
      onDone: onConnectionClosed(),
      // If an error occurs, print the error message in the console
      onError: (error) {
        print('WebSocket error: $error');
        onConnectionClosed();
      },
    );
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(json.encode(message));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}