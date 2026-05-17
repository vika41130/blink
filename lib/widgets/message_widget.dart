import 'dart:async';

import 'package:blink/get_it_setup.dart';
import 'package:blink/models/message.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/widgets/custom_widgets/thanos_dissolve_wrapper.dart';
import 'package:flutter/material.dart';

class MessageWidget extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String currentUserId;
  final String receiverId;
  final String messageId;

  const MessageWidget({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.receiverId,
    required this.messageId,
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget>
    with SingleTickerProviderStateMixin {
  Timer? _deleteTimer;
  Timer? _animationTimer;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _scheduleDeletion();
    _scheduleWithAnimation();
  }

  void _scheduleDeletion() {
    final remaining = widget.message.deleteAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _deleteMessage();
      });
      return;
    }
    _deleteTimer = Timer(remaining, _deleteMessage);
  }

  void _scheduleWithAnimation() {
    final remaining = widget.message.deleteAt.difference(
      DateTime.now().add(const Duration(seconds: 1)),
    );
    _animationTimer = Timer(remaining, () {
      setState(() {
        _isRemoving = true;
      });
    });
  }

  void _deleteMessage() async {
    await getIt<ChatService>().deleteMessage(
      currentUserId: widget.currentUserId,
      receiverId: widget.receiverId,
      messageId: widget.messageId,
    );
  }

  @override
  void dispose() {
    _deleteTimer?.cancel();
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ThanosDissolveWrapper(
        isDeleted: _isRemoving,
        messageColor: Colors.blue,
        onAnimationComplete: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isMe ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.message.text,
            style: TextStyle(
              color: widget.isMe ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
