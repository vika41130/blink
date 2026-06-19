import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/models/contact.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late final FocusNode searchFieldFocusNode;
  late final TextEditingController _searchController;
  List<Contact> contacts = [];
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    searchFieldFocusNode = FocusNode();
    _searchController = TextEditingController();
    isLoading = false;
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
    _searchController.dispose();
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
            controller: _searchController,
            focusNode: searchFieldFocusNode,
            onTapOutside: (event) {
              setState(() {});
              searchFieldFocusNode.unfocus();
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
                child: Icon(CupertinoIcons.search, size: appIconMidSize),
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
                          searchFieldFocusNode.unfocus();
                          _loadContacts();
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
                borderRadius: BorderRadius.circular(appTextInputBorderRadius),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) async {
              final currentUserId =
                  getIt<CacheService>().getString(cacheKeyUserId) ?? '';
              contacts = await getIt<ContactService>().getContacts(
                currentUserId: currentUserId,
                searchText: value.trim(),
              );
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

  Widget _buildUserListTile(Contact contact) {
    final username = contact.username;
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
            CupertinoIcons.person,
            size: appIconMidSize,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            contact.displayName,
            style: const TextStyle(fontSize: fontSizeMedium),
          ),
          trailing: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              CupertinoIcons.star_fill,
              size: appIconMidSize,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () async {
              final String currentUserId =
                  getIt<CacheService>().getString(cacheKeyUserId) ?? '';
              await getIt<ContactService>().removeContact(
                currentUserId,
                username,
              );
            },
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
                      displayName: contact.displayName,
                    ),
              ),
            );
          },
        ),
      ],
    );
  }
}
