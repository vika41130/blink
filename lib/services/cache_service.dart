import 'package:blink/get_it_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  bool getBool(String key) => getIt<SharedPreferences>().getBool(key) ?? false;
  Future<void> setBool(String key, bool value) => getIt<SharedPreferences>().setBool(key, value);

  String? getString(String key) => getIt<SharedPreferences>().getString(key);
  Future<void> setString(String key, String value) =>
      getIt<SharedPreferences>().setString(key, value);
}

const cacheKeyUsername = 'blinkCacheKeyUsername';
const cacheKeyIsSignedIn = 'blinkCacheKeyIsSignedIn';