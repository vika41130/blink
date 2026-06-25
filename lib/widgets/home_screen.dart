import 'dart:async';

import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/ad_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/chat_list_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/auth_screen.dart';
import 'package:blink/widgets/chat_list_screen.dart';
import 'package:blink/widgets/contact_screen.dart';
import 'package:blink/widgets/profile_screen.dart';
import 'package:blink/widgets/qr_image_screen.dart';
import 'package:blink/widgets/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  Widget content = const SizedBox.shrink();
  late Timer _clockTimer;
  String _time = '';
  bool _contactsLocked = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _bannerAdDismissed = false;

  @override
  void initState() {
    super.initState();
    _contactsLocked = getIt<CacheService>().getBool(cacheKeyContactsLocked);
    _time = _formatTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _selectedTab == 0) {
        final newTime = _formatTime();
        if (newTime != _time) {
          setState(() => _time = newTime);
        }
      }
    });
    // Background preload contacts progressively
    getIt<ContactService>().loadContactsProgressively(
      currentUserId: getIt<CacheService>().getString(cacheKeyUserId) ?? '',
    );
    _loadBannerAd();
  }

  void _loadBannerAd() {
    final prefs = getIt<SharedPreferences>();
    if (!AdService.canShowAd(prefs, AdService.keyAdHomeScreen)) return;
    _bannerAd = AdService.createBannerAd(
      onAdLoaded: (_) {
        if (mounted) {
          AdService.markAdShown(
            getIt<SharedPreferences>(),
            AdService.keyAdHomeScreen,
          );
          setState(() => _isBannerAdLoaded = true);
        }
      },
      onAdFailedToLoad: (ad, _) {
        ad.dispose();
        _bannerAd = null;
      },
    )..load();
  }

  String _formatTime() {
    return DateFormat('HH:mm:ss').format(DateTime.now());
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return getIt<AppLocalizations>().goodMorning;
    if (hour < 17) return getIt<AppLocalizations>().goodAfternoon;
    if (hour < 21) return getIt<AppLocalizations>().goodEvening;
    return getIt<AppLocalizations>().goodNight;
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _bannerAd?.dispose();
    super.dispose();
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 16 : 0,
              vertical: isSelected ? 6 : 0,
            ),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSelected ? filledIcon : outlinedIcon,
              size: appIconBottomBarSize,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar:
          _selectedTab == 2
              ? AppBar(
                toolbarHeight: appBarHeight,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: Icon(CupertinoIcons.qrcode),
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
                    valueListenable: getIt<ChatListService>().unreadCount,
                    builder:
                        (_, count, __) => IconButton(
                          icon: Badge(
                            isLabelVisible: count > 0,
                            label: Text(count > 9 ? '9+' : '$count'),
                            child: Icon(CupertinoIcons.chat_bubble_2),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChatListScreen(),
                              ),
                            );
                            getIt<ChatListService>().resetCount();
                          },
                        ),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.power),
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
                  if (_selectedTab != 1)
                    IconButton(
                      icon: Icon(CupertinoIcons.search),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                    ),
                  if (_selectedTab != 1)
                    ValueListenableBuilder<int>(
                      valueListenable: getIt<ChatListService>().unreadCount,
                      builder:
                          (_, count, __) => IconButton(
                            icon: Badge(
                              isLabelVisible: count > 0,
                              label: Text(count > 9 ? '9+' : '$count'),
                              child: Icon(CupertinoIcons.chat_bubble_2),
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChatListScreen(),
                                ),
                              );
                              getIt<ChatListService>().resetCount();
                            },
                          ),
                    ),
                  IconButton(
                    icon: Icon(CupertinoIcons.power),
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
        bottom: false,
        child: Stack(
          children: [
            Padding(
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
                                        fontSize: fontSizeLarge * 1.5,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: const Alignment(0, -0.6),
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
                  if (_selectedTab == 0 &&
                      _isBannerAdLoaded &&
                      _bannerAd != null &&
                      !_bannerAdDismissed)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            appBarHeight +
                            appPaddingSmall * 2 +
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: SizedBox(
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 40,
              right: 40,
              bottom: MediaQuery.of(context).padding.bottom + appPaddingSmall,
              child: Container(
                height: appBarHeight,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(appBarHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildTabItem(
                      CupertinoIcons.house_fill,
                      CupertinoIcons.house,
                      0,
                      () {
                        setState(() {
                          _selectedTab = 0;
                          content = const SizedBox.shrink();
                        });
                      },
                    ),
                    if (!_contactsLocked)
                      _buildTabItem(
                        CupertinoIcons.person_2_fill,
                        CupertinoIcons.person_2,
                        1,
                        () {
                          AdService.showInterstitialAd(
                            getIt<SharedPreferences>(),
                            AdService.keyAdContactsScreen,
                          );
                          setState(() {
                            _selectedTab = 1;
                            _bannerAdDismissed = true;
                            content = const ContactScreen();
                          });
                        },
                      ),
                    _buildTabItem(
                      CupertinoIcons.person_fill,
                      CupertinoIcons.person,
                      2,
                      () {
                        AdService.showInterstitialAd(
                          getIt<SharedPreferences>(),
                          AdService.keyAdProfileScreen,
                        );
                        setState(() {
                          _selectedTab = 2;
                          _bannerAdDismissed = true;
                          content = ProfileScreen(
                            onLockChanged: () {
                              setState(() {
                                _contactsLocked = getIt<CacheService>().getBool(
                                  cacheKeyContactsLocked,
                                );
                              });
                            },
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
