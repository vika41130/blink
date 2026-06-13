import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatSettingsScreen extends StatefulWidget {
  final String receiverName;

  const ChatSettingsScreen({super.key, required this.receiverName});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: appBarIconSize),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          getIt<AppLocalizations>().chatSettings,
          style: TextStyle(
            fontSize: appTitleFontSize,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
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
                          Icons.access_time,
                          size: appIconMidSize,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: null,
                      ),
                      SizedBox(width: appPaddingSmall),
                      Text(
                        DateFormat('yyyy.MM.dd HH:mm').format(snapshot.data!),
                        style: TextStyle(
                          fontSize: fontSizeMedium,
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      Icons.swipe_right,
                      size: appIconMidSize,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: null,
                  ),
                  SizedBox(width: appPaddingSmall),
                  Text(
                    getIt<AppLocalizations>().swipeRightToRemove,
                    style: TextStyle(
                      fontSize: fontSizeMedium,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: appPaddingSmall),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      size: appIconMidSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {},
                  ),
                  SizedBox(width: appPaddingSmall),
                  Text(
                    widget.receiverName,
                    style: TextStyle(
                      fontSize: fontSizeMedium,
                      color: Theme.of(context).colorScheme.onSurface,
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
                          isAdded ? Icons.star : Icons.star_border,
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
                      Text(
                        isAdded
                            ? getIt<AppLocalizations>().savedContact
                            : getIt<AppLocalizations>().saveContact,
                        style: TextStyle(
                          fontSize: fontSizeMedium,
                          color: Theme.of(context).colorScheme.onSurface,
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
