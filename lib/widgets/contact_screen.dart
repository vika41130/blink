import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late final FocusNode searchFieldFocusNode;
  List<String> contacts = [];
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    searchFieldFocusNode = FocusNode();
    _loadContacts();
    getIt<ContactService>().contactsVersion.addListener(_onContactsChanged);
  }

  void _onContactsChanged() {
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    contacts = await getIt<ContactService>().getContacts(
      currentUserId: getIt<CacheService>().getString(cacheKeyUserId) ?? '',
      searchText: '',
    );
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    getIt<ContactService>().contactsVersion.removeListener(_onContactsChanged);
    searchFieldFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: appPaddingSmall),
        SizedBox(
          height: appTextInputHeight,
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
              hintText: getIt<AppLocalizations>().searchContact,
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
                borderRadius: BorderRadius.circular(appTextInputBorderRadius),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) async {
              final currentUserId =
                  getIt<CacheService>().getString(cacheKeyUserId) ?? '';
              isLoading = true;
              setState(() {});
              contacts = await getIt<ContactService>().getContacts(
                currentUserId: currentUserId,
                searchText: value.trim(),
              );
              isLoading = false;
              setState(() {});
            },
          ),
        ),
        SizedBox(height: appPaddingMid),
        Expanded(
          child:
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.separated(
                    controller: _scrollController,
                    itemCount: contacts.length,
                    separatorBuilder:
                        (context, index) =>
                            SizedBox(height: appPaddingSmall / 2),
                    itemBuilder: (context, index) {
                      return _buildUserListTile(contacts[index]);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildUserListTile(String username) {
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
            color: getIt<AppThemes>().themeData.colorScheme.primary,
          ),
          title: Text(
            username,
            style: const TextStyle(fontSize: fontSizeMedium),
          ),
          onTap: () async {
            final String currentUserId =
                getIt<CacheService>().getString(cacheKeyUserId) ?? '';
            final String receiverId =
                await getIt<AuthService>().getDocIdByUsername(username) ?? '';
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder:
                    (context) => ChatScreen(
                      currentUserId: currentUserId,
                      receiverId: receiverId,
                      receiverName: username,
                    ),
              ),
            );
          },
        ),
        FutureBuilder<DateTime?>(
          future: getIt<ChatService>().getLastChatTime(
            getIt<CacheService>().getString(cacheKeyUserId) ?? '',
            username,
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
                    color:
                        getIt<AppThemes>()
                            .themeData
                            .colorScheme
                            .onSurfaceVariant,
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
