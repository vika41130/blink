import 'package:blink/get_it_setup.dart';
import 'package:blink/services/contact_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  bool getBool(String key) => getIt<SharedPreferences>().getBool(key) ?? false;
  Future<void> setBool(String key, bool value) =>
      getIt<SharedPreferences>().setBool(key, value);

  String? getString(String key) => getIt<SharedPreferences>().getString(key);
  Future<void> setString(String key, String value) =>
      getIt<SharedPreferences>().setString(key, value);
  void clearCache() {
    getIt<CacheService>().setString(cacheKeyUsername, '');
    getIt<CacheService>().setBool(cacheKeyIsSignedIn, false);
    getIt<CacheService>().setString(cacheKeyUserId, '');
    getIt<CacheService>().setString('lastPinVerified', '');
    getIt<CacheService>().setString('pincodeDurationMinutes', '');
    getIt<CacheService>().setBool(cacheKeyPinVerificationEnabled, true);
    getIt<ContactService>().clearCache();
  }
}

const cacheKeyUsername = 'blinkCacheKeyUsername';
const cacheKeyIsSignedIn = 'blinkCacheKeyIsSignedIn';
const cacheKeyUserId = 'cacheKeyUserId';
const cacheKeyPinVerificationEnabled = 'pinVerificationEnabled';
