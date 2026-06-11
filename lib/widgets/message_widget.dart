import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:blink/get_it_setup.dart';
import 'package:blink/models/message.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/custom_widgets/message_removal_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';

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

class _MessageWidgetState extends State<MessageWidget> {
  Timer? _deleteTimer;
  Timer? _animationTimer;
  Timer? _fadeTimer;
  bool _isRemoving = false;
  double _fadeProgress = 0.0; // 0.0 = full color, 1.0 = ghost gray
  Uint8List? _imageBytes;

  static const _ghostGray = Color(0xFF2C2C2E);
  static const _fadeDuration = 3; // seconds before deletion to start fading

  @override
  void initState() {
    super.initState();
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

  void _openFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                iconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.save_alt,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => _saveToGallery(context),
                  ),
                ],
              ),
              body: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      await ImageGallerySaverPlus.saveImage(
        _imageBytes!,
        quality: 100,
        name: 'blink_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved to gallery')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save image')));
      }
    }
  }

  @override
  void dispose() {
    _deleteTimer?.cancel();
    _animationTimer?.cancel();
    _fadeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MessageRemovalWrapper(
      isRemoving: _isRemoving,
      onAnimationComplete: () {},
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            widget.message.isImage && _imageBytes != null
                ? GestureDetector(
                  onTap: () => _openFullScreenImage(context),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: appMessageMarginVertical,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(appBorderRadius),
                          child: Image.memory(
                            _imageBytes!,
                            width: 180,
                            height: 180,
                            fit: BoxFit.cover,
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
                  ),
                )
                : Container(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 4,
                    top: 8,
                    bottom: 8,
                  ),
                  margin: const EdgeInsets.symmetric(
                    vertical: appMessageMarginVertical,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          widget.isMe
                              ? [
                                _lerpGradientColor(const Color(0xFF00F2FE)),
                                _lerpGradientColor(const Color(0xFF4FACFE)),
                              ]
                              : [
                                _lerpGradientColor(const Color(0xFF7F00FF)),
                                _lerpGradientColor(const Color(0xFFE100FF)),
                              ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                      bottomRight: Radius.circular(widget.isMe ? 4 : 16),
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
                            children: [WidgetSpan(child: SizedBox(width: 52))],
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
                            color: Colors.black.withValues(alpha: 0.3),
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
          ],
        ),
      ),
    );
  }
}
