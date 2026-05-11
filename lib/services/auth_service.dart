import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/loading_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/widgets/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  isSignedIn() {
    return CacheService().getBool(cacheKeyIsSignedIn);
  }

  goIn(String username, String passcode, bool isSignInMode) async {
    final userCollection = getIt<FirebaseFirestore>().collection('users');
    if (isSignInMode) {
      getIt<LoadingService>().showGlobalLoading();
      QuerySnapshot querySnapshot =
          await userCollection
              .where('username', isEqualTo: username)
              .limit(1)
              .get();
      getIt<LoadingService>().hideLoading();
      if (querySnapshot.docs.isEmpty) {
        getIt<ToastificationService>().showError(
          getIt<AppLocalizations>().userNameNotExisting,
        );
      } else {
        var doc = querySnapshot.docs.first;
        if (doc['passcode'] == passcode) {
          getIt<LoadingService>().showGlobalLoading(
            message: getIt<AppLocalizations>().signInSuccess,
          );
          await Future.delayed(const Duration(seconds: 1));
          getIt<LoadingService>().hideLoading();
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
          getIt<CacheService>().setString(cacheKeyUsername, username);
          getIt<CacheService>().setBool(cacheKeyIsSignedIn, true);
          getIt<CacheService>().setString(cacheKeyUserId, doc.id);
        } else {
          getIt<ToastificationService>().showError(
            getIt<AppLocalizations>().passcodeNotCorrect,
          );
        }
      }
    } else {
      getIt<LoadingService>().showGlobalLoading();
      QuerySnapshot querySnapshot =
          await userCollection
              .where('username', isEqualTo: username)
              .limit(1)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        getIt<ToastificationService>().showError(
          getIt<AppLocalizations>().userNameAlreadyExisted,
        );
        getIt<LoadingService>().hideLoading();
        return;
      }
      try {
        final user = await userCollection.add({
          "username": username,
          "passcode": passcode,
        });
        getIt<CacheService>().setString(cacheKeyUsername, username);
        getIt<CacheService>().setBool(cacheKeyIsSignedIn, true);
        getIt<CacheService>().setString(cacheKeyUserId, user.id);
      } catch (e) {
        getIt<ToastificationService>().showError(
          getIt<AppLocalizations>().signUpFailed,
        );
      }
      getIt<LoadingService>().hideLoading();
      getIt<LoadingService>().showGlobalLoading(
        message: getIt<AppLocalizations>().createUserSuccess,
      );
      getIt<LoadingService>().hideLoading();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }
}
