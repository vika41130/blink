import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/models/message.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/custom_widgets/message_removal_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';

class MessageWidget extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String currentUserId;
  final String receiverId;
  final String messageId;
  final FocusNode? chatFocusNode;
  final TextEditingController? chatController;

  const MessageWidget({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.receiverId,
    required this.messageId,
    this.chatFocusNode,
    this.chatController,
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget>
    with SingleTickerProviderStateMixin {
  Timer? _deleteTimer;
  Timer? _animationTimer;
  Timer? _fadeTimer;
  bool _isRemoving = false;
  double _fadeProgress = 0.0; // 0.0 = full color, 1.0 = ghost gray
  Uint8List? _imageBytes;
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  static const _ghostGray = Color(0xFF2C2C2E);
  static const _fadeDuration = 3; // seconds before deletion to start fading

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _decodeImage();
    _scheduleDeletion();
    _scheduleWithAnimation();
    _scheduleFade();
  }

  void _scheduleFade() {
    final remaining = widget.message.deleteAt.difference(DateTime.now());
    final fadeStart = remaining - Duration(seconds: _fadeDuration);

    if (fadeStart <= Duration.zero) {
      // Already within fade window
      _startFadeTimer();
    } else {
      _fadeTimer = Timer(fadeStart, _startFadeTimer);
    }
  }

  void _startFadeTimer() {
    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      final remaining = widget.message.deleteAt.difference(DateTime.now());
      final progress =
          1.0 -
          (remaining.inMilliseconds / (_fadeDuration * 1000)).clamp(0.0, 1.0);
      setState(() {
        _fadeProgress = progress;
      });
      if (progress >= 1.0) {
        _fadeTimer?.cancel();
      }
    });
  }

  Color _lerpGradientColor(Color original) {
    return Color.lerp(original, _ghostGray, _fadeProgress)!;
  }

  void _decodeImage() {
    if (widget.message.isImage) {
      _imageBytes = base64Decode(widget.message.imageBase64!);
    }
  }

  void _scheduleDeletion() {
    final remaining = widget.message.deleteAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _deleteMessage();
      });
      return;
    }
    _deleteTimer = Timer(remaining, () {
      if (mounted) _deleteMessage();
    });
  }

  void _scheduleWithAnimation() {
    final remaining = widget.message.deleteAt.difference(
      DateTime.now().add(const Duration(seconds: 1)),
    );
    if (remaining <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isRemoving = true;
          });
        }
      });
      return;
    }
    _animationTimer = Timer(remaining, () {
      if (mounted) {
        setState(() {
          _isRemoving = true;
        });
      }
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
    _fadeTimer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final overlay = Overlay.of(context);
    final menuColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    const menuHeight = 96.0;

    // Clamp position so menu stays within visible area
    final maxTop =
        screenSize.height - bottomPadding - keyboardHeight - menuHeight - 16;
    final minTop = topPadding + 16;
    final clampedTop = position.dy.clamp(minTop, maxTop);

    late final OverlayEntry entry;

    String? textBeforeMenu;

    void onTextChanged() {
      final savedText = textBeforeMenu;
      if (savedText != null && widget.chatController != null) {
        widget.chatController!.removeListener(onTextChanged);
        widget.chatController!.text = savedText;
        widget.chatController!.selection = TextSelection.collapsed(
          offset: savedText.length,
        );
      }
      if (entry.mounted) entry.remove();
    }

    textBeforeMenu = widget.chatController?.text;

    void closeMenu() {
      widget.chatController?.removeListener(onTextChanged);
      if (entry.mounted) entry.remove();
    }

    widget.chatController?.addListener(onTextChanged);

    entry = OverlayEntry(
      builder:
          (ctx) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              closeMenu();
            },
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: clampedTop,
                  child: Center(
                    child: Material(
                      elevation: 8,
                      color: menuColor,
                      borderRadius: BorderRadius.circular(8),
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!widget.message.isImage)
                              InkWell(
                                onTap: () {
                                  closeMenu();
                                  _copyMessage();
                                },
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Text(getIt<AppLocalizations>().copy),
                                  ),
                                ),
                              ),
                            InkWell(
                              onTap: () {
                                closeMenu();
                                _deleteMessage();
                              },
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Text(getIt<AppLocalizations>().delete),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    overlay.insert(entry);
  }

  void _openImageViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => _ImageViewerScreen(imageBytes: _imageBytes!),
      ),
    );
  }

  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: widget.message.text));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: MessageRemovalWrapper(
        isRemoving: _isRemoving,
        onAnimationComplete: () {},
        child: GestureDetector(
          onTapUp: (details) {
            if (widget.message.isImage && _imageBytes != null) {
              _openImageViewer(context);
            } else {
              _showContextMenu(context, details.globalPosition);
            }
          },
          child: Align(
            alignment:
                widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment:
                  widget.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                widget.message.isImage && _imageBytes != null
                    ? Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: appMessageMarginVertical,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              appBorderRadius,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 180,
                                maxHeight: 240,
                              ),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: Center(
                                      child: Icon(Icons.broken_image, size: 40),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat(
                                  'HH:mm',
                                ).format(widget.message.timestamp),
                                style: TextStyle(
                                  fontSize: fontSizeSmall - 3,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: appMessageMarginVertical,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                          bottomRight: Radius.circular(widget.isMe ? 4 : 16),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 4,
                              top: 8,
                              bottom: 8,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    widget.isMe
                                        ? [
                                          _lerpGradientColor(
                                            const Color(0xFF00F2FE),
                                          ).withValues(alpha: 0.7),
                                          _lerpGradientColor(
                                            const Color(0xFF4FACFE),
                                          ).withValues(alpha: 0.7),
                                        ]
                                        : [
                                          _lerpGradientColor(
                                            const Color(0xFF7F00FF),
                                          ).withValues(alpha: 0.7),
                                          _lerpGradientColor(
                                            const Color(0xFFE100FF),
                                          ).withValues(alpha: 0.7),
                                        ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(
                                  widget.isMe ? 16 : 4,
                                ),
                                bottomRight: Radius.circular(
                                  widget.isMe ? 4 : 16,
                                ),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 0),
                                  child: RichText(
                                    text: TextSpan(
                                      text: widget.message.text,
                                      style: TextStyle(
                                        fontSize: fontSizeMedium,
                                        color: Colors.white,
                                      ),
                                      children: [
                                        WidgetSpan(child: SizedBox(width: 52)),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      DateFormat(
                                        'HH:mm',
                                      ).format(widget.message.timestamp),
                                      style: TextStyle(
                                        fontSize: fontSizeSmall - 3,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageViewerScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const _ImageViewerScreen({required this.imageBytes});

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  double _dragOffset = 0;
  double _opacity = 1.0;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      _opacity = (1.0 - (_dragOffset.abs() / 300)).clamp(0.4, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > 100) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
        _opacity = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: _opacity),
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.back,
            size: appBarIconSize,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.square_arrow_down,
              size: appBarIconSize,
              color: Colors.white,
            ),
            onPressed: () async {
              await ImageGallerySaverPlus.saveImage(
                widget.imageBytes,
                quality: 100,
                name: 'blink_${DateTime.now().millisecondsSinceEpoch}',
              );
              if (context.mounted) {
                getIt<ToastificationService>().showToast(
                  getIt<AppLocalizations>().saveToGallery,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Center(
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Opacity(
                opacity: _opacity,
                child: InteractiveViewer(
                  child: Image.memory(widget.imageBytes),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
