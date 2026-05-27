import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/widgets/auth_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkErrorHandler {
  static Future<bool> isOffline() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.none);
  }

  /// Returns true if offline (and handles sign out). Use before any network call.
  static Future<bool> checkAndHandle() async {
    if (await isOffline()) {
      await handleNetworkError();
      return true;
    }
    return false;
  }

  static Future<void> handleNetworkError() async {
    getIt<ToastificationService>().showError('Network error. Signing out.');
    await Future.delayed(const Duration(seconds: 2));
    getIt<CacheService>().clearCache();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  static bool isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('unavailable') ||
        msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('timeoutexception');
  }
}
