import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ChatSettingsScreen extends StatefulWidget {
  final String receiverName;
  final String receiverId;
  final String? displayName;

  const ChatSettingsScreen({
    super.key,
    required this.receiverName,
    required this.receiverId,
    this.displayName,
  });

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  bool _isEditingUsername = false;
  late final TextEditingController _usernameController;
  late final FocusNode _usernameFocusNode;
  String _currentNickName = '';

  @override
  void initState() {
    super.initState();
    _currentNickName = widget.displayName ?? widget.receiverName;
    _usernameController = TextEditingController(text: _currentNickName);
    _usernameFocusNode = FocusNode();
  }

  Future<void> _saveNickName() async {
    final newNickName = _usernameController.text.trim();
    if (newNickName.isEmpty || newNickName == _currentNickName) {
      setState(() => _isEditingUsername = false);
      return;
    }
    final success = await getIt<AuthService>().updateUserNickName(
      widget.receiverName,
      newNickName,
    );
    if (!mounted) return;
    if (success) {
      setState(() {
        _currentNickName = newNickName;
        _isEditingUsername = false;
      });
      getIt<ContactService>().updateNickNameInCache(
        widget.receiverName,
        newNickName,
      );
      getIt<ToastificationService>().showToast('Nickname updated');
    } else {
      getIt<ToastificationService>().showToast('Failed to update nickname');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: appBarIconSize),
          onPressed: () => Navigator.of(context).pop(_currentNickName),
        ),
        title: Text(
          getIt<AppLocalizations>().chatSettings,
          style: TextStyle(
            fontSize: fontSizeLarge,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: appPaddingSmall * 2,
            vertical: appPaddingSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DateTime?>(
                future: getIt<ChatService>().getLastChatTime(
                  getIt<CacheService>().getString(cacheKeyUserId) ?? '',
                  widget.receiverName,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SizedBox.shrink();
                  }
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.clock,
                          size: appIconMidSize,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: null,
                      ),
                      SizedBox(width: appPaddingSmall),
                      Expanded(
                        child: Text(
                          DateFormat('yyyy.MM.dd HH:mm').format(snapshot.data!),
                          style: TextStyle(
                            fontSize: fontSizeMedium,
                            fontFamily: 'monospace',
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: appPaddingSmall),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.hand_draw,
                      size: appIconMidSize,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: null,
                  ),
                  SizedBox(width: appPaddingSmall),
                  Expanded(
                    child: Text(
                      getIt<AppLocalizations>().swipeRightToRemove,
                      style: TextStyle(
                        fontSize: fontSizeMedium,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: appPaddingSmall),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.hand_point_right,
                      size: appIconMidSize,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: null,
                  ),
                  SizedBox(width: appPaddingSmall),
                  Expanded(
                    child: Text(
                      getIt<AppLocalizations>().tripleTapToBlock,
                      style: TextStyle(
                        fontSize: fontSizeMedium,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: appPaddingSmall),
              _isEditingUsername
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.checkmark,
                          size: appIconMidSize,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          _saveNickName();
                        },
                      ),
                      SizedBox(width: appPaddingSmall),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: appIconMidSize,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _usernameController.text =
                              _currentNickName.isNotEmpty
                                  ? _currentNickName
                                  : widget.receiverName;
                          setState(() => _isEditingUsername = false);
                        },
                      ),
                      SizedBox(width: appPaddingSmall),
                      Expanded(
                        child: TextField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          maxLines: 2,
                          minLines: 1,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              userNickNameMaxLength,
                            ),
                          ],
                          onTapOutside: (_) {
                            _usernameFocusNode.unfocus();
                          },
                          style: const TextStyle(
                            fontSize: appTextInputFontSize,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.all(
                              appTextInputContentPadding,
                            ),
                            hintText: widget.receiverName,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                appTextInputBorderRadius,
                              ),
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
                  )
                  : Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.pencil,
                          size: appIconMidSize,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          _usernameController.text = _currentNickName;
                          setState(() => _isEditingUsername = true);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _usernameFocusNode.requestFocus();
                          });
                        },
                      ),
                      SizedBox(width: appPaddingSmall),
                      Expanded(
                        child: Text(
                          _currentNickName.isNotEmpty
                              ? _currentNickName
                              : widget.receiverName,
                          style: TextStyle(
                            fontSize: fontSizeMedium,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
              SizedBox(height: appPaddingSmall),
              FutureBuilder<bool>(
                future: getIt<ContactService>().isContactAdded(
                  getIt<CacheService>().getString(cacheKeyUserId) ?? '',
                  widget.receiverName,
                ),
                builder: (context, snapshot) {
                  final isAdded = snapshot.data == true;
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isAdded
                              ? CupertinoIcons.star_fill
                              : CupertinoIcons.star,
                          size: appIconMidSize,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () async {
                          final currentUserId =
                              getIt<CacheService>().getString(cacheKeyUserId) ??
                              '';
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
                      ),
                      SizedBox(width: appPaddingSmall),
                      Expanded(
                        child: Text(
                          isAdded
                              ? getIt<AppLocalizations>().savedContact
                              : getIt<AppLocalizations>().saveContact,
                          style: TextStyle(
                            fontSize: fontSizeMedium,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: appPaddingSmall),
              FutureBuilder<bool>(
                future: getIt<ChatService>().isChatBlocked(
                  currentUserId:
                      getIt<CacheService>().getString(cacheKeyUserId) ?? '',
                  receiverId: widget.receiverId,
                ),
                builder: (context, snapshot) {
                  final isBlocked = snapshot.data == true;
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isBlocked
                              ? CupertinoIcons.lock_open
                              : CupertinoIcons.lock,
                          size: appIconMidSize,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () async {
                          final currentUserId =
                              getIt<CacheService>().getString(cacheKeyUserId) ??
                              '';
                          final success = await getIt<ChatService>()
                              .setChatBlocked(
                                currentUserId: currentUserId,
                                receiverId: widget.receiverId,
                                isBlocked: !isBlocked,
                              );
                          if (success) {
                            getIt<ToastificationService>().showToast(
                              !isBlocked ? 'Chat blocked' : 'Chat unblocked',
                            );
                          }
                          setState(() {});
                        },
                      ),
                      SizedBox(width: appPaddingSmall),
                      Expanded(
                        child: Text(
                          isBlocked
                              ? getIt<AppLocalizations>().unblockChat
                              : getIt<AppLocalizations>().blockChat,
                          style: TextStyle(
                            fontSize: fontSizeMedium,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
