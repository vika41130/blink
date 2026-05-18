import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/models/user.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _HomeContenttState();
}

class _HomeContenttState extends State<SearchScreen> {
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
    return Column(
      children: [
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
                hintText: getIt<AppLocalizations>().searchHint,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(appTextInputBorderRadius),
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
            ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final user = searchResults[index];
                return _buildUserListTile(user);
              },
            )
            : searchFieldFocusNode.hasFocus && searchResults.isEmpty
            ? Text(
              getIt<AppLocalizations>().noUserFound,
              style: TextStyle(
                color:
                    getIt<AppThemes>().themeData.colorScheme.onSurfaceVariant,
                fontSize: fontSizeMedium,
              ),
            )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildUserListTile(User user) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor:
            getIt<AppThemes>().themeData.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.person,
          color: getIt<AppThemes>().themeData.colorScheme.primary,
        ),
      ),
      title: Text(
        user.username,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: FutureBuilder<bool>(
        future: getIt<ContactService>().isContactAdded(
          getIt<CacheService>().getString(cacheKeyUserId) ?? '',
          user.username,
        ),
        builder: (context, snapshot) {
          final isAdded = snapshot.data == true;
          return IconButton(
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
            await getIt<AuthService>().getDocIdByUsername(user.username) ?? '';
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
    );
  }
}
