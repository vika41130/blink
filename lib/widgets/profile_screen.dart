import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/chat_message_duration_screen.dart';
import 'package:blink/widgets/lock_contacts_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onLockChanged;
  const ProfileScreen({super.key, this.onLockChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: appPaddingSmall,
        right: appPaddingSmall,
        bottom: appPaddingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              getIt<CacheService>().getString(cacheKeyUsername) ?? '',
              style: TextStyle(
                fontSize: fontSizeLarge * 1.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: appFormItemMargin),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.timer_outlined,
                  size: appIconMidSize,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LockContactsScreen(),
                    ),
                  );
                  onLockChanged?.call();
                },
              ),
              SizedBox(width: appPaddingSmall),
              Expanded(
                child: Text(
                  getIt<AppLocalizations>().lockContacts,
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: appFormItemMargin),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  size: appIconMidSize,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatMessageDurationScreen(),
                    ),
                  );
                },
              ),
              SizedBox(width: appPaddingSmall),
              Expanded(
                child: Text(
                  'Chat message duration',
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
