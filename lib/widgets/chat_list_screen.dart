import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/chat_list_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String _currentUserId =
      getIt<CacheService>().getString(cacheKeyUserId) ?? '';

  @override
  void initState() {
    super.initState();
    getIt<ChatListService>().setViewingChatList(true);
  }

  @override
  void dispose() {
    getIt<ChatListService>().setViewingChatList(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: appBarIconSize),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          getIt<AppLocalizations>().chat,
          style: TextStyle(
            fontSize: fontSizeLarge,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<ChatRoom>>(
        valueListenable: getIt<ChatListService>().chatRooms,
        builder: (context, rooms, _) {
          if (rooms.isEmpty) {
            return const SizedBox.shrink();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: appPaddingSmall),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => SizedBox(height: appPaddingSmall / 2),
            itemBuilder: (context, index) {
              final room = rooms[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: appPaddingSmall,
                ),
                leading: Container(
                  width: appSixedBoxSizeLarge,
                  height: appSixedBoxSizeLarge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                title: Text(
                  room.displayName,
                  style: const TextStyle(fontSize: fontSizeMedium),
                ),
                subtitle: Text(
                  room.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSizeSmall,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatScreen(
                            currentUserId: _currentUserId,
                            receiverId: room.receiverId,
                            receiverName: room.receiverName,
                            displayName: room.displayName,
                          ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
