import 'dart:io';

import 'package:blink/get_it_setup.dart';
import 'package:blink/models/message.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:blink/widgets/home_screen.dart';
import 'package:blink/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messagesStream = getIt<ChatService>().getMessages(
      widget.currentUserId,
      widget.receiverId,
    );
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
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
    // Screen protection disabled - screen_protector incompatible with Xcode 16
  }

  Future<void> _disableProtection() async {
    // Screen protection disabled - screen_protector incompatible with Xcode 16
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
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          actions: [
            FutureBuilder<bool>(
              future: getIt<ContactService>().isContactAdded(
                getIt<CacheService>().getString(cacheKeyUserId) ?? '',
                widget.receiverName,
              ),
              builder: (context, snapshot) {
                final isAdded = snapshot.data == true;
                return IconButton(
                  icon: Icon(
                    isAdded ? Icons.star : Icons.star_border,
                    size: appIconLargeSize,
                  ),
                  onPressed: () async {
                    final currentUserId =
                        getIt<CacheService>().getString(cacheKeyUserId) ?? '';
                    if (isAdded) {
                      await getIt<ContactService>().removeContact(
                        currentUserId,
                        widget.receiverName,
                      );
                    } else {
                      await getIt<ContactService>().saveContact(
                        currentUserId,
                        widget.receiverName,
                      );
                    }
                    setState(() {});
                  },
                );
              },
            ),
          ],
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
                      return ListView.separated(
                        reverse: true,
                        itemCount: messages.length,
                        separatorBuilder:
                            (context, index) => const SizedBox.shrink(),
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
                SizedBox(height: appMessageMarginVertical),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 5,
                        minLines: 1,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(appMessageMaxLength),
                        ],
                        style: const TextStyle(fontSize: appTextInputFontSize),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: appTextInputContentPadding * 1.5,
                            vertical: appTextInputContentPadding,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_hasText)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                      appTextInputBorderRadius,
                                    ),
                                    onTap: _pickAndSendImage,
                                    child: Icon(
                                      Icons.photo_outlined,
                                      size: appIconLargeSize,
                                      color:
                                          getIt<AppThemes>()
                                              .themeData
                                              .colorScheme
                                              .tertiary,
                                    ),
                                  ),
                                ),
                              if (_hasText)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                      appTextInputBorderRadius,
                                    ),
                                    onTap: _sendMessage,
                                    child: Icon(
                                      Icons.send,
                                      size: appIconLargeSize,
                                      color:
                                          getIt<AppThemes>()
                                              .themeData
                                              .colorScheme
                                              .tertiary,
                                    ),
                                  ),
                                ),
                              SizedBox(width: appTextInputContentPadding / 2),
                            ],
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
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
