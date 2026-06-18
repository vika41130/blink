import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/models/user.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:blink/widgets/qr_scanner_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final FocusNode _searchFocusNode;
  late final TextEditingController _searchController;
  List<User> _searchResults = [];
  String _lastSearched = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
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
          getIt<AppLocalizations>().search,
          style: TextStyle(
            fontSize: fontSizeLarge,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.qrcode_viewfinder),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRScannerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: appPaddingSmall),
          child: Column(
            children: [
              SizedBox(height: appPaddingSmall),
              SizedBox(
                height: appTextInputHeight,
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onTapOutside: (event) {
                      _searchFocusNode.unfocus();
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(userNameMaxLength),
                    ],
                    style: const TextStyle(fontSize: appTextInputFontSize),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.only(
                        right: appTextInputContentPadding,
                        top: appTextInputContentPadding,
                        bottom: appTextInputContentPadding,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(
                          left: appTextInputContentPadding,
                          right: appTextInputContentPadding / 2,
                        ),
                        child: Icon(
                          CupertinoIcons.search,
                          size: appIconMidSize,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _searchFocusNode.unfocus();
                                  setState(() => _searchResults = []);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: appTextInputContentPadding,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.xmark,
                                    size: appIconMidSize,
                                  ),
                                ),
                              )
                              : null,
                      suffixIconConstraints: const BoxConstraints(
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
                      final keyword = value.trim();
                      _lastSearched = keyword;
                      if (keyword.isEmpty) {
                        setState(() => _searchResults = []);
                        return;
                      }
                      final results = await getIt<AuthService>().searchUsers(
                        keyword,
                      );
                      if (_lastSearched == keyword && mounted) {
                        setState(() {
                          _searchResults = results;
                        });
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: appFormItemMargin),
              _searchResults.isNotEmpty
                  ? Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return _buildUserListTile(user);
                      },
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
    return GestureDetector(
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
                  displayName:
                      user.userNickName.isNotEmpty
                          ? user.userNickName
                          : user.username,
                ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: appPaddingSmall / 2,
          vertical: appPaddingSmall / 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: appIconMidSize,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: appPaddingSmall),
            Text(
              user.userNickName.isNotEmpty ? user.userNickName : user.username,
              style: const TextStyle(fontSize: fontSizeMedium),
            ),
          ],
        ),
      ),
    );
  }
}
