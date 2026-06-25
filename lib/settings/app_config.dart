import 'package:flutter/foundation.dart';

class AppConfig {
  // Automatically true in debug mode, false in release
  static bool get isDebug => kDebugMode;

  // AdMob: use test ads in debug, real ads in release
  static bool get useTestAds => isDebug;

  // APNs: sandbox in debug, production in release
  static String get apnsEnvironment => isDebug ? 'development' : 'production';
}
