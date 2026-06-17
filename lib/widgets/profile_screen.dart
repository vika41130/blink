import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/auth_screen.dart';
import 'package:blink/widgets/notification_screen.dart';
import 'package:blink/widgets/qr_image_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom AppBar area
        SafeArea(
          bottom: false,
          child: SizedBox(
            height: appBarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: appPaddingSmall),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.qr_code,
                      size: appIconLargeSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QRImageScreen(),
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable:
                            getIt<NotificationService>().unreadCount,
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
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Username below appbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: appPaddingSmall),
          child: Center(
            child: Text(
              getIt<CacheService>().getString(cacheKeyUsername) ?? '',
              style: TextStyle(
                fontSize: fontSizeLarge * 1.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
