import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      contacts = await getIt<ContactService>().getContacts(
        currentUserId: getIt<CacheService>().getString(cacheKeyUserId) ?? '',
        searchText: '',
      );
      isLoading = false;
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchFieldFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(getIt<AppLocalizations>().contactTitle)),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: appPadding,
            right: appPadding,
            bottom: appPadding,
          ),
          child: Column(
            children: [
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
                    hintText: getIt<AppLocalizations>().searchHint,
                    prefixIcon: Icon(Icons.search),
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
              SizedBox(height: appPaddingSmall),
              Expanded(
                child:
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          controller: _scrollController,
                          itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            return _buildUserListTile(contacts[index]);
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserListTile(String username) {
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
        username,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: FutureBuilder<bool>(
        future: getIt<ContactService>().isContactAdded(
          getIt<CacheService>().getString(cacheKeyUserId) ?? '',
          username,
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
                  username,
                );
              } else {
                await getIt<ContactService>().saveContact(
                  currentUserId,
                  username,
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
    );
  }
}
