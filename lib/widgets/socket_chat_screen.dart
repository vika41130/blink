import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class SocketChatScreen extends StatefulWidget {
  const SocketChatScreen({super.key});

  @override
  State<SocketChatScreen> createState() => _SocketChatScreenState();
}

class _SocketChatScreenState extends State<SocketChatScreen> {
  final TextEditingController _controller = TextEditingController();

  // 1. Declare the WebSocket Channel
  late WebSocketChannel _channel;

  // Local list to display messages in the UI
  final List<String> _messageList = [];

  @override
  void initState() {
    super.initState();

    // 2. Connect to your WebSocket Server
    // For testing, you can use the public Echo server: wss://echo.websocket.events
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://echo.websocket.events'),
    );
  }

  // 3. Send a message through the socket channel
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      _channel.sink.add(_controller.text); // Send raw text string to server

      setState(() {
        _messageList.insert(0, "Sent: ${_controller.text}");
      });

      _controller.clear();
    }
  }

  @override
  void dispose() {
    // 4. CRITICAL: Always close the socket connection to prevent memory leaks!
    _channel.sink.close(status.goingAway);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WebSocket Chat")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 5. Listen to incoming server messages using StreamBuilder
            Expanded(
              child: StreamBuilder(
                stream: _channel.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  // Capture incoming data from server and add to local list
                  if (snapshot.hasData) {
                    final incomingMessage = snapshot.data.toString();
                    // Basic duplicate check for UI rendering purposes
                    if (_messageList.isEmpty ||
                        !_messageList.first.contains(incomingMessage)) {
                      _messageList.insert(0, "Received: $incomingMessage");
                    }
                  }

                  return ListView.builder(
                    reverse: true, // New messages appear at the bottom
                    itemCount: _messageList.length,
                    itemBuilder: (context, index) {
                      return ListTile(title: Text(_messageList[index]));
                    },
                  );
                },
              ),
            ),

            // Input field and send button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
