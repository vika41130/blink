import 'dart:io';

import 'package:blink/settings/fixed_settings.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static const keyAdHomeScreen = 'lastAdShown_homeScreen';
  static const keyAdContactsScreen = 'lastAdShown_contactsScreen';
  static const keyAdProfileScreen = 'lastAdShown_profileScreen';
  static const keyAdChatSettings = 'lastAdShown_chatSettings';

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // test
    } else {
      return 'ca-app-pub-3940256099942544/2934735716'; // test
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // test
    } else {
      return 'ca-app-pub-3940256099942544/4411468910'; // test
    }
  }

  static InterstitialAd? _interstitialAd;

  static bool canShowAd(SharedPreferences prefs, String key) {
    final lastShown = prefs.getString(key);
    if (lastShown == null) return true;
    final lastTime = DateTime.tryParse(lastShown);
    if (lastTime == null) return true;
    return DateTime.now().difference(lastTime).inMinutes >= adCooldownMinutes;
  }

  static void markAdShown(SharedPreferences prefs, String key) {
    prefs.setString(key, DateTime.now().toIso8601String());
  }

  static BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  static void showInterstitialAd(SharedPreferences prefs, String key) {
    if (!canShowAd(prefs, key)) return;
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      markAdShown(prefs, key);
      _interstitialAd = null;
      loadInterstitialAd();
    }
  }
}
