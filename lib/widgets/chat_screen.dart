import 'package:blink/get_it_setup.dart';
import 'package:blink/models/message.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:blink/widgets/home_screen.dart';
import 'package:blink/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _enableProtection();
  }

  @override
  void dispose() {
    _disableProtection();
    super.dispose();
  }

  Future<void> _enableProtection() async {
    await ScreenProtector.protectDataLeakageOn();
    await ScreenProtector.preventScreenshotOn();
  }

  Future<void> _disableProtection() async {
    await ScreenProtector.protectDataLeakageOff();
    await ScreenProtector.preventScreenshotOff();
  }

  void _sendMessage() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    _messageController.clear();
    await getIt<ChatService>().sendMessage(
      currentUserId: widget.currentUserId,
      receiverId: widget.receiverId,
      messageText: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents default back navigation
      onPopInvokedWithResult: (didPop, result) async {
        // safety check: if the system somehow already popped, don't repeat it
        if (didPop) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.receiverName,
            style: TextStyle(
              fontSize: appTitleFontSize,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: appPadding,
              right: appPadding,
              bottom: appPadding,
            ),
            child: Column(
              children: [
                // 1. Live Chat Stream
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: getIt<ChatService>().getMessages(
                      widget.currentUserId,
                      widget.receiverId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final messages = snapshot.data!;
                      return ListView.builder(
                        reverse:
                            true, // Pushes UI elements to the bottom of the screen
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final bool isMe =
                              message.senderId == widget.currentUserId;
                          return MessageWidget(
                            key: ValueKey(message.messageId),
                            message: message,
                            isMe: isMe,
                            currentUserId: widget.currentUserId,
                            receiverId: widget.receiverId,
                            messageId: message.messageId,
                          );
                        },
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: appTextInputHeight,
                        child: Center(
                          child: TextField(
                            controller: _messageController,
                            maxLines: appTextInputMaxLines,
                            minLines: appTextInputMinLines,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(
                                appMessageMaxLength,
                              ),
                            ],
                            style: const TextStyle(
                              fontSize: appTextInputFontSize,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: appTextInputContentPadding,
                                vertical: appTextInputContentPadding,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  appTextInputBorderRadius,
                                ),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor:
                                  getIt<AppThemes>()
                                      .themeData
                                      .colorScheme
                                      .surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: appIconSmallSize,
                      icon: Icon(
                        Icons.send,
                        color:
                            getIt<AppThemes>().themeData.colorScheme.tertiary,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
