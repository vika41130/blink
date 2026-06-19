import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:blink/get_it_setup.dart';
import 'package:blink/models/message.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/home_screen.dart';
import 'package:blink/widgets/message_widget.dart';
import 'package:blink/widgets/chat_settings_screen.dart';
import 'package:blink/widgets/custom_widgets/smoke_animation.dart';
import 'package:blink/widgets/custom_widgets/typing_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  final String? displayName;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
    this.displayName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  late final Stream<List<MessageModel>> _messagesStream;
  late final Stream<bool> _typingStream;
  StreamSubscription<bool>? _typingSubscription;
  bool _hasText = false;
  bool _isReceiverTyping = false;
  final Set<String> _smokingMessages = {};
  Timer? _typingTimer;
  Timer? _typingHideTimer;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  final GlobalKey _messageAreaKey = GlobalKey();
  String _displayName = '';
  bool _isBlocked = false;
  bool _isChatBlocked = false;
  StreamSubscription<bool>? _blockSubscription;

  @override
  void initState() {
    super.initState();
    _displayName = widget.displayName ?? widget.receiverName;
    if (widget.displayName == null) _loadDisplayName();
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
    _scrollController.addListener(_onScroll);
    _blockSubscription = getIt<ChatService>()
        .chatBlockedStream(
          currentUserId: widget.currentUserId,
          receiverId: widget.receiverId,
        )
        .listen((blocked) {
          if (mounted && blocked != _isChatBlocked) {
            setState(() => _isChatBlocked = blocked);
          }
        });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _typingHideTimer?.cancel();
    _tapTimer?.cancel();
    _typingSubscription?.cancel();
    _blockSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageFocusNode.dispose();
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

  void _onScroll() {
    final shouldShow = _scrollController.offset > 100;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
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
    // Check if either person has blocked this chat
    final blockedByMe = await getIt<ChatService>().isChatBlocked(
      currentUserId: widget.currentUserId,
      receiverId: widget.receiverId,
    );
    final blockedByThem = await getIt<ChatService>().isChatBlocked(
      currentUserId: widget.receiverId,
      receiverId: widget.currentUserId,
    );
    if (blockedByMe || blockedByThem) {
      getIt<ToastificationService>().showToast('Chat is blocked');
      return;
    }
    _messageController.clear();
    _messageFocusNode.requestFocus();
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
  }

  Future<void> _pickAndSendImage() async {
    // Check if either person has blocked this chat
    final blockedByMe = await getIt<ChatService>().isChatBlocked(
      currentUserId: widget.currentUserId,
      receiverId: widget.receiverId,
    );
    final blockedByThem = await getIt<ChatService>().isChatBlocked(
      currentUserId: widget.receiverId,
      receiverId: widget.currentUserId,
    );
    if (blockedByMe || blockedByThem) {
      getIt<ToastificationService>().showToast('Chat is blocked');
      return;
    }
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

  Future<void> _loadDisplayName() async {
    final user = await getIt<AuthService>().getUserByUsername(
      widget.receiverName,
    );
    if (user != null && user.userNickName.isNotEmpty && mounted) {
      setState(() => _displayName = user.userNickName);
    }
  }

  int _tapCount = 0;
  Timer? _tapTimer;

  void _onAppBarTap() {
    _messageFocusNode.unfocus();
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 400), () {
      _tapCount = 0;
    });
    if (_tapCount >= 3) {
      _tapCount = 0;
      _tapTimer?.cancel();
      setState(() => _isBlocked = !_isBlocked);
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _messageFocusNode.unfocus(),
            child: AppBar(
              title: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onAppBarTap,
                child: Text(
                  _displayName,
                  style: TextStyle(
                    fontSize: fontSizeLarge,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back, size: appBarIconSize),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(CupertinoIcons.ellipsis, size: appBarIconSize),
                  onPressed: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ChatSettingsScreen(
                              receiverName: widget.receiverName,
                              receiverId: widget.receiverId,
                              displayName: _displayName,
                            ),
                      ),
                    );
                    if (result != null && result.isNotEmpty && mounted) {
                      setState(() => _displayName = result);
                    }
                    _messageFocusNode.unfocus();
                  },
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _messageFocusNode.unfocus(),
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
                        key: _messageAreaKey,
                        child: Stack(
                          children: [
                            StreamBuilder<List<MessageModel>>(
                              stream: _messagesStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox.shrink();
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final messages = snapshot.data!;
                                return ListView.separated(
                                  controller: _scrollController,
                                  reverse: true,
                                  itemCount: messages.length,
                                  separatorBuilder:
                                      (context, index) =>
                                          const SizedBox.shrink(),
                                  itemBuilder: (context, index) {
                                    final message = messages[index];
                                    final bool isMe =
                                        message.senderId ==
                                        widget.currentUserId;
                                    return _smokingMessages.contains(
                                          message.messageId,
                                        )
                                        ? const SizedBox.shrink()
                                        : isMe
                                        ? _DismissibleMessage(
                                          messageId: message.messageId,
                                          onDismissed: (position) {
                                            showSmokeEffect(context, position);
                                            setState(() {
                                              _smokingMessages.add(
                                                message.messageId,
                                              );
                                            });
                                            getIt<ChatService>().deleteMessage(
                                              currentUserId:
                                                  widget.currentUserId,
                                              receiverId: widget.receiverId,
                                              messageId: message.messageId,
                                            );
                                          },
                                          child: MessageWidget(
                                            key: ValueKey(
                                              'msg_${message.messageId}',
                                            ),
                                            message: message,
                                            isMe: isMe,
                                            currentUserId: widget.currentUserId,
                                            receiverId: widget.receiverId,
                                            messageId: message.messageId,
                                            chatFocusNode: _messageFocusNode,
                                            chatController: _messageController,
                                          ),
                                        )
                                        : MessageWidget(
                                          key: ValueKey(
                                            'msg_${message.messageId}',
                                          ),
                                          message: message,
                                          isMe: isMe,
                                          currentUserId: widget.currentUserId,
                                          receiverId: widget.receiverId,
                                          messageId: message.messageId,
                                          chatFocusNode: _messageFocusNode,
                                          chatController: _messageController,
                                        );
                                  },
                                );
                              },
                            ),
                            if (_showScrollToBottom)
                              Positioned(
                                bottom: 8,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _scrollToBottom,
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.chevron_down,
                                      size: 24,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
                            child: const RepaintBoundary(
                              child: TypingIndicator(),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _messageFocusNode,
                              enabled: !_isChatBlocked,
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
                                suffixIcon:
                                    _isChatBlocked
                                        ? null
                                        : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!_hasText)
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  customBorder:
                                                      const CircleBorder(),
                                                  onTap: _pickAndSendImage,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    child: Icon(
                                                      CupertinoIcons.photo,
                                                      size: appIconMidSize,
                                                      color:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .tertiary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (_hasText)
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  customBorder:
                                                      const CircleBorder(),
                                                  onTap: _sendMessage,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    child: Icon(
                                                      CupertinoIcons
                                                          .paperplane_fill,
                                                      size: appIconMidSize,
                                                      color:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .tertiary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            SizedBox(
                                              width:
                                                  appTextInputContentPadding /
                                                  2,
                                            ),
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
            if (_isBlocked)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {},
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
