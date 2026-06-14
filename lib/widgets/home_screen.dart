import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/auth_screen.dart';
import 'package:blink/widgets/notification_screen.dart';
import 'package:blink/widgets/contact_screen.dart';
import 'package:blink/widgets/profile_screen.dart';
import 'package:blink/widgets/qr_scanner_screen.dart';
import 'package:blink/widgets/newchat_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  Widget content = const NewChatScreen();

  @override
  void initState() {
    super.initState();
    // Background preload contacts progressively
    getIt<ContactService>().loadContactsProgressively(
      currentUserId: getIt<CacheService>().getString(cacheKeyUserId) ?? '',
    );
  }

  Widget _buildTabItem(IconData icon, int index, VoidCallback onTap) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            width: 52,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Icon(
                  icon,
                  size: appIconLargeSize,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: Text(
          getIt<AppLocalizations>().homeTitle,
          style: TextStyle(
            fontSize: fontSizeLarge,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () {
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => const QRScannerScreen(),
                ),
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: getIt<NotificationService>().unreadCount,
            builder:
                (_, count, __) => IconButton(
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text(
                      count > notificationBadgeMax
                          ? '$notificationBadgeMax+'
                          : '$count',
                    ),
                    child: Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () {
                    getIt<NotificationService>().resetCount();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
          ),
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () {
              getIt<CacheService>().clearCache();
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: appPaddingSmall,
            right: appPaddingSmall,
            bottom: appPaddingSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: content)],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: appBarHeight,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _buildTabItem(Icons.home_filled, 0, () {
              setState(() {
                _selectedTab = 0;
                content = const NewChatScreen();
              });
            }),
            _buildTabItem(Icons.contacts, 1, () {
              setState(() {
                _selectedTab = 1;
                content = const ContactScreen();
              });
            }),
            _buildTabItem(Icons.person, 2, () {
              setState(() {
                _selectedTab = 2;
                content = const ProfileScreen();
              });
            }),
          ],
        ),
      ),
    );
  }
}
