import 'dart:async';
import 'dart:io';

import 'package:blink/get_it_setup.dart';
import 'package:blink/models/message.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/home_screen.dart';
import 'package:blink/widgets/message_widget.dart';
import 'package:blink/widgets/custom_widgets/smoke_animation.dart';
import 'package:blink/widgets/custom_widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  late final Stream<bool> _typingStream;
  StreamSubscription<bool>? _typingSubscription;
  bool _hasText = false;
  bool _isReceiverTyping = false;
  DateTime? _lastChatTime;
  final Set<String> _smokingMessages = {};
  Timer? _typingTimer;
  Timer? _typingHideTimer;

  @override
  void initState() {
    super.initState();
    _loadLastChatTime();
    _messagesStream = getIt<ChatService>().getMessages(
      widget.currentUserId,
      widget.receiverId,
    );
    _typingStream = getIt<ChatService>().getTypingStatus(
      currentUserId: widget.currentUserId,
      receiverId: widget.receiverId,
    );
    _typingSubscription = _typingStream.listen((isTyping) {
      if (!mounted) return;
      if (isTyping && !_isReceiverTyping) {
        _typingHideTimer?.cancel();
        setState(() => _isReceiverTyping = true);
      } else if (!isTyping && _isReceiverTyping) {
        _typingHideTimer?.cancel();
        setState(() => _isReceiverTyping = false);
      }
    });
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
      _onUserTyping();
    });
    _enableProtection();
    getIt<NotificationService>().setCurrentChat(widget.receiverId);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _typingHideTimer?.cancel();
    _typingSubscription?.cancel();
    getIt<ChatService>().setTypingStatus(
      currentUserId: widget.currentUserId,
      receiverId: widget.receiverId,
      isTyping: false,
    );
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

  bool _lastTypingState = false;

  void _onUserTyping() {
    final text = _messageController.text;
    _typingTimer?.cancel();
    if (text.isEmpty) {
      if (_lastTypingState) {
        _lastTypingState = false;
        getIt<ChatService>().setTypingStatus(
          currentUserId: widget.currentUserId,
          receiverId: widget.receiverId,
          isTyping: false,
        );
      }
      return;
    }
    if (!_lastTypingState) {
      _lastTypingState = true;
      getIt<ChatService>().setTypingStatus(
        currentUserId: widget.currentUserId,
        receiverId: widget.receiverId,
        isTyping: true,
      );
    }
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _lastTypingState = false;
      getIt<ChatService>().setTypingStatus(
        currentUserId: widget.currentUserId,
        receiverId: widget.receiverId,
        isTyping: false,
      );
    });
  }

  void _sendMessage() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    _messageController.clear();
    _typingTimer?.cancel();
    getIt<ChatService>().setTypingStatus(
      currentUserId: widget.currentUserId,
      receiverId: widget.receiverId,
      isTyping: false,
    );
    await getIt<ChatService>().sendMessage(
      currentUserId: widget.currentUserId,
      receiverId: widget.receiverId,
      messageText: text,
    );
    _refreshLastChatTime();
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
    _refreshLastChatTime();
  }

  void _refreshLastChatTime() {
    setState(() {
      _lastChatTime = DateTime.now();
    });
  }

  Future<void> _loadLastChatTime() async {
    final time = await getIt<ChatService>().getLastChatTime(
      widget.currentUserId,
      widget.receiverName,
    );
    if (mounted) {
      setState(() {
        _lastChatTime = time;
      });
    }
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
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.receiverName,
                style: TextStyle(
                  fontSize: appTitleFontSize,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: appPaddingSmall),
              if (_lastChatTime != null)
                Text(
                  DateFormat('yyyy.MM.dd HH:mm').format(_lastChatTime!),
                  style: TextStyle(
                    fontSize: fontSizeSmall - 2,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: appBarIconSize),
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
                    size: appBarIconSize,
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
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: appPaddingSmall,
                right: appPaddingSmall,
                bottom: appPaddingSmall,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<MessageModel>>(
                      stream: _messagesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                            return _smokingMessages.contains(message.messageId)
                                ? const SizedBox.shrink()
                                : _DismissibleMessage(
                                  messageId: message.messageId,
                                  onDismissed: (position) {
                                    showSmokeEffect(context, position);
                                    setState(() {
                                      _smokingMessages.add(message.messageId);
                                    });
                                    getIt<ChatService>().deleteMessage(
                                      currentUserId: widget.currentUserId,
                                      receiverId: widget.receiverId,
                                      messageId: message.messageId,
                                    );
                                  },
                                  child: MessageWidget(
                                    key: ValueKey('msg_${message.messageId}'),
                                    message: message,
                                    isMe: isMe,
                                    currentUserId: widget.currentUserId,
                                    receiverId: widget.receiverId,
                                    messageId: message.messageId,
                                  ),
                                );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: appMessageMarginVertical),
                  SizedBox(
                    height: 16,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedOpacity(
                        opacity: _isReceiverTyping ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const RepaintBoundary(child: TypingIndicator()),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: 5,
                          minLines: 1,
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
                                            Theme.of(
                                              context,
                                            ).colorScheme.tertiary,
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
                                            Theme.of(
                                              context,
                                            ).colorScheme.tertiary,
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
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
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
      ),
    );
  }
}

class _DismissibleMessage extends StatefulWidget {
  final String messageId;
  final void Function(Offset position) onDismissed;
  final Widget child;

  const _DismissibleMessage({
    required this.messageId,
    required this.onDismissed,
    required this.child,
  });

  @override
  State<_DismissibleMessage> createState() => _DismissibleMessageState();
}

class _DismissibleMessageState extends State<_DismissibleMessage> {
  Offset? _lastPosition;

  void _capturePosition() {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final pos = box.localToGlobal(Offset.zero);
      _lastPosition = Offset(
        pos.dx + box.size.width / 2,
        pos.dy + box.size.height / 2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.messageId),
      direction: DismissDirection.startToEnd,
      movementDuration: const Duration(milliseconds: 200),
      confirmDismiss: (_) async {
        _capturePosition();
        return true;
      },
      onDismissed: (_) {
        if (_lastPosition != null) {
          widget.onDismissed(_lastPosition!);
        }
      },
      background: const SizedBox.shrink(),
      child: widget.child,
    );
  }
}
