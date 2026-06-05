import 'dart:io';

import 'package:blink/get_it_setup.dart';
import 'package:blink/models/message.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:blink/widgets/home_screen.dart';
import 'package:blink/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
  late final Stream<List<MessageModel>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = getIt<ChatService>().getMessages(
      widget.currentUserId,
      widget.receiverId,
    );
    _enableProtection();
    getIt<NotificationService>().setCurrentChat(widget.receiverId);
  }

  @override
  void dispose() {
    getIt<NotificationService>().setCurrentChat(null);
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

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
    );
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    await getIt<ChatService>().sendImageMessage(
      currentUserId: widget.currentUserId,
      receiverId: widget.receiverId,
      imageFile: imageFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
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
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final messages = snapshot.data!;
                      return ListView.builder(
                        reverse: true,
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
                    GestureDetector(
                      onTap: _pickAndSendImage,
                      child: Icon(
                        Icons.photo_outlined,
                        size: appIconSmallSize,
                        color:
                            getIt<AppThemes>().themeData.colorScheme.tertiary,
                      ),
                    ),
                    SizedBox(width: appPadding),
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
                    SizedBox(width: appPadding),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Icon(
                        Icons.send,
                        size: appIconSmallSize,
                        color:
                            getIt<AppThemes>().themeData.colorScheme.tertiary,
                      ),
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
