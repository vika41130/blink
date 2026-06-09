import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/auth_screen.dart';
import 'package:blink/widgets/notification_screen.dart';
import 'package:blink/widgets/contact_screen.dart';
import 'package:blink/widgets/profile_screen.dart';
import 'package:blink/widgets/qr_scanner_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget content = const ContactScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: Text(
          getIt<AppLocalizations>().homeTitle,
          style: TextStyle(
            fontSize: appTitleFontSize,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
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
            left: appPadding,
            right: appPadding,
            bottom: appPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: content)],
          ),
        ),
      ),
      // stop here
      bottomNavigationBar: BottomAppBar(
        height: appBarHeight,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home_filled),
              onPressed: () {
                setState(() {
                  content = const ContactScreen();
                });
              },
            ),
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
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
