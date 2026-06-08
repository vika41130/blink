import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:blink/get_it_setup.dart';
import 'package:blink/models/message.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
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
  bool _isRemoving = false;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _decodeImage();
    _scheduleDeletion();
    _scheduleWithAnimation();
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
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.save_alt, color: Colors.white),
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
                    child: ClipRRect(
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
                  ),
                )
                : Container(
                  padding: const EdgeInsets.all(appMessagePadding),
                  margin: const EdgeInsets.symmetric(
                    vertical: appMessageMarginVertical,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.isMe
                            ? getIt<AppThemes>().themeData.colorScheme.primary
                            : getIt<AppThemes>()
                                .themeData
                                .colorScheme
                                .secondary,
                    borderRadius: BorderRadius.circular(
                      appTextInputBorderRadius,
                    ),
                  ),
                  child: Text(
                    widget.message.text,
                    style: TextStyle(
                      color:
                          widget.isMe
                              ? getIt<AppThemes>()
                                  .themeData
                                  .colorScheme
                                  .surfaceContainerHighest
                              : getIt<AppThemes>()
                                  .themeData
                                  .colorScheme
                                  .surfaceBright,
                    ),
                  ),
                ),
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                DateFormat('dd/MM HH:mm').format(widget.message.timestamp),
                style: TextStyle(
                  fontSize: fontSizeSmall - 2,
                  color: getIt<AppThemes>().themeData.colorScheme.onSurface
                      .withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
