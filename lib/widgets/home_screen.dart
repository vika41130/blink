import 'dart:async';
import 'dart:ui';

import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/auth_screen.dart';
import 'package:blink/widgets/notification_screen.dart';
import 'package:blink/widgets/contact_screen.dart';
import 'package:blink/widgets/profile_screen.dart';
import 'package:blink/widgets/qr_image_screen.dart';
import 'package:blink/widgets/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  Widget content = const SizedBox.shrink();
  DateTime? _lastPinVerified;
  late Timer _clockTimer;
  String _time = '';

  @override
  void initState() {
    super.initState();
    _time = _formatTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _selectedTab == 0) {
        final newTime = _formatTime();
        if (newTime != _time) {
          setState(() => _time = newTime);
        }
      }
    });
    // Load cached pin verification time
    final cachedTime = getIt<CacheService>().getString('lastPinVerified');
    if (cachedTime != null && cachedTime.isNotEmpty) {
      _lastPinVerified = DateTime.tryParse(cachedTime);
    }
    // Background preload contacts progressively
    getIt<ContactService>().loadContactsProgressively(
      currentUserId: getIt<CacheService>().getString(cacheKeyUserId) ?? '',
    );
  }

  String _formatTime() {
    return DateFormat('HH:mm:ss').format(DateTime.now());
  }

  Duration _getPincodeDuration() {
    final cachedMinutes = int.tryParse(
      getIt<CacheService>().getString('pincodeDurationMinutes') ?? '',
    );
    return cachedMinutes != null
        ? Duration(minutes: cachedMinutes)
        : const Duration(hours: 6);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _showPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (ctx) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(appBorderRadius * 4),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                  width: mediumBorderWidth,
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: appPaddingSmall * 2,
                  vertical: appPaddingSmall * 3,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter pin',
                      style: TextStyle(fontSize: fontSizeSmall),
                    ),
                    const SizedBox(height: appPaddingSmall * 2),
                    Pinput(
                      controller: pinController,
                      autofocus: true,
                      obscureText: true,
                      defaultPinTheme: PinTheme(
                        width: 28,
                        height: 28,
                        textStyle: TextStyle(
                          fontSize: fontSizeMedium,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                            width: mediumBorderWidth,
                          ),
                        ),
                      ),
                      showCursor: true,
                      cursor: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      separatorBuilder:
                          (index) => const SizedBox(width: appPaddingMid),
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                      onCompleted: (pin) async {
                        final userId =
                            getIt<CacheService>().getString(cacheKeyUserId) ??
                            '';
                        final user = await getIt<AuthService>().getUserById(
                          userId,
                        );
                        if (user != null && user.pin == pin) {
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          _lastPinVerified = DateTime.now();
                          getIt<CacheService>().setString(
                            'lastPinVerified',
                            _lastPinVerified!.toIso8601String(),
                          );
                          setState(() {
                            _selectedTab = 1;
                            content = const ContactScreen();
                          });
                        } else {
                          getIt<ToastificationService>().showToast(
                            'Incorrect pin',
                          );
                          pinController.setText('');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildTabItem(
    IconData filledIcon,
    IconData outlinedIcon,
    int index,
    VoidCallback onTap,
  ) {
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
                  isSelected ? filledIcon : outlinedIcon,
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
      appBar:
          _selectedTab == 2
              ? AppBar(
                toolbarHeight: appBarHeight,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: Icon(Icons.qr_code),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRImageScreen(),
                      ),
                    );
                  },
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
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ],
              )
              : AppBar(
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
                    icon: Icon(Icons.search),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
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
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
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
            children: [
              Expanded(
                child:
                    _selectedTab == 0
                        ? Column(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: appPaddingSmall,
                                ),
                                child: Text(
                                  _getGreeting(),
                                  style: TextStyle(
                                    fontSize: fontSizeLarge,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _time,
                                      style: TextStyle(
                                        fontSize: fontSizeLarge * 2.5,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    SizedBox(height: appPaddingSmall),
                                    Text(
                                      DateFormat(
                                        'EEEE, MMMM d, yyyy',
                                      ).format(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: fontSizeMedium,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                        : content,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: appBarHeight,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _buildTabItem(Icons.home_filled, Icons.home_outlined, 0, () {
              setState(() {
                _selectedTab = 0;
                content = const SizedBox.shrink();
              });
            }),
            _buildTabItem(Icons.contacts, Icons.contacts_outlined, 1, () {
              final pinEnabled =
                  getIt<SharedPreferences>().getBool(
                    cacheKeyPinVerificationEnabled,
                  ) ??
                  true;
              if (!pinEnabled) {
                setState(() {
                  _selectedTab = 1;
                  content = const ContactScreen();
                });
              } else if (_lastPinVerified != null &&
                  DateTime.now().difference(_lastPinVerified!) <
                      _getPincodeDuration()) {
                setState(() {
                  _selectedTab = 1;
                  content = const ContactScreen();
                });
              } else {
                _showPinDialog();
              }
            }),
            _buildTabItem(Icons.person, Icons.person_outline, 2, () {
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
