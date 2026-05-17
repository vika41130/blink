import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _HomeContenttState();
}

class _HomeContenttState extends State<SearchScreen> {
  late final FocusNode searchFieldFocusNode;
  List<Map<String, dynamic>> searchResults = [];

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
          child: TextField(
            focusNode: searchFieldFocusNode,
            onTapOutside: (event) {
              setState(() {});
              searchFieldFocusNode.unfocus();
            },
            maxLength: pinInputMaxLength,
            style: const TextStyle(fontSize: appTextInputFontSize),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.only(right: appTextInputContentPadding),
              hintText: getIt<AppLocalizations>().searchHint,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(appTextInputBorderRadius),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        SizedBox(height: formItemMargin),
        searchResults.isNotEmpty
            ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final user = searchResults[index];
                // save contact feature
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        getIt<AppThemes>()
                            .themeData
                            .colorScheme
                            .surfaceContainerHighest,
                    child: Icon(
                      Icons.person,
                      color: getIt<AppThemes>().themeData.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    user['username'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: appIconMidSize,
                  ),
                  onTap: () async {
                    final String currentUserId =
                        getIt<CacheService>().getString(cacheKeyUserId) ?? '';
                    final String receiverId =
                        await getIt<AuthService>().getDocIdByUsername(
                          user['username'],
                        ) ??
                        '';
                    navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder:
                            (context) => ChatScreen(
                              currentUserId: currentUserId,
                              receiverId: receiverId,
                              receiverName: user['username'],
                            ),
                      ),
                    );
                  },
                );
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
}
