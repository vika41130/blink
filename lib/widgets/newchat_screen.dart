import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/models/user.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  late final FocusNode searchFieldFocusNode;
  List<User> searchResults = [];

  @override
  void initState() {
    super.initState();
    searchFieldFocusNode = FocusNode();
  }

  @override
  void dispose() {
    searchFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: appBarIconSize),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          getIt<AppLocalizations>().newChat,
          style: TextStyle(
            fontSize: appTitleFontSize,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: appPaddingSmall,
            right: appPaddingSmall,
            bottom: appPaddingSmall,
          ),
          child: Column(
            children: [
              SizedBox(height: appPaddingSmall),
              SizedBox(
                height: appTextInputHeight,
                child: Center(
                  child: TextField(
                    focusNode: searchFieldFocusNode,
                    onTapOutside: (event) {
                      setState(() {});
                      searchFieldFocusNode.unfocus();
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(pinInputMaxLength),
                    ],
                    style: const TextStyle(fontSize: appTextInputFontSize),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.only(
                        right: appTextInputContentPadding,
                        top: appTextInputContentPadding,
                        bottom: appTextInputContentPadding,
                      ),
                      hintText: getIt<AppLocalizations>().searchUsername,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(
                          left: appTextInputContentPadding,
                          right: appTextInputContentPadding / 2,
                        ),
                        child: Icon(Icons.search, size: appIconMidSize),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          appTextInputBorderRadius,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    onChanged: (value) async {
                      final user = await getIt<AuthService>().getUserByUsername(
                        value.trim(),
                      );
                      if (user != null) {
                        setState(() {
                          searchResults = [user];
                        });
                      } else {
                        setState(() {
                          searchResults = [];
                        });
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: appFormItemMargin),
              searchResults.isNotEmpty
                  ? Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        return _buildUserListTile(user);
                      },
                    ),
                  )
                  : searchFieldFocusNode.hasFocus && searchResults.isEmpty
                  ? Text(
                    getIt<AppLocalizations>().noUserFound,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: fontSizeMedium,
                    ),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserListTile(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          visualDensity: const VisualDensity(vertical: -3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(appTextInputBorderRadius),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: appPaddingSmall / 2),
          minLeadingWidth: 0,
          horizontalTitleGap: appPaddingSmall,
          leading: Icon(
            Icons.person,
            size: appIconMidSize,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            user.username,
            style: const TextStyle(fontSize: fontSizeMedium),
          ),
          trailing: FutureBuilder<bool>(
            future: getIt<ContactService>().isContactAdded(
              getIt<CacheService>().getString(cacheKeyUserId) ?? '',
              user.username,
            ),
            builder: (context, snapshot) {
              final isAdded = snapshot.data == true;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(isAdded ? Icons.star : Icons.star_border),
                iconSize: appIconMidSize,
                onPressed: () async {
                  final String currentUserId =
                      getIt<CacheService>().getString(cacheKeyUserId) ?? '';
                  if (isAdded) {
                    await getIt<ContactService>().removeContact(
                      currentUserId,
                      user.username,
                    );
                  } else {
                    await getIt<ContactService>().saveContact(
                      currentUserId,
                      user.username,
                    );
                  }
                  setState(() {});
                },
              );
            },
          ),
          onTap: () async {
            final String currentUserId =
                getIt<CacheService>().getString(cacheKeyUserId) ?? '';
            final String receiverId =
                await getIt<AuthService>().getDocIdByUsername(user.username) ??
                '';
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder:
                    (context) => ChatScreen(
                      currentUserId: currentUserId,
                      receiverId: receiverId,
                      receiverName: user.username,
                    ),
              ),
            );
          },
        ),
        FutureBuilder<DateTime?>(
          future: getIt<ChatService>().getLastChatTime(
            getIt<CacheService>().getString(cacheKeyUserId) ?? '',
            user.username,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(right: appPaddingSmall / 2),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat('yyyy.MM.dd HH:mm').format(snapshot.data!),
                  style: TextStyle(
                    fontSize: fontSizeSmall - 2,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
