import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/models/user.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/loading_service.dart';
import 'package:blink/services/network_error_handler.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/widgets/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  isSignedIn() {
    return CacheService().getBool(cacheKeyIsSignedIn);
  }

  goIn(String username, String passcode, bool isSignInMode) async {
    if (await NetworkErrorHandler.isOffline()) {
      getIt<ToastificationService>().showToast('Network error');
      return;
    }
    final userCollection = getIt<FirebaseFirestore>().collection('users');
    if (isSignInMode) {
      getIt<LoadingService>().showGlobalLoading();
      try {
        QuerySnapshot querySnapshot =
            await userCollection
                .where('username', isEqualTo: username)
                .limit(1)
                .get();
        getIt<LoadingService>().hideLoading();
        if (querySnapshot.docs.isEmpty) {
          getIt<ToastificationService>().showToast(
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
            await getIt<NotificationService>().init();
          } else {
            getIt<ToastificationService>().showToast(
              getIt<AppLocalizations>().passcodeNotCorrect,
            );
          }
        }
      } catch (e) {
        getIt<LoadingService>().hideLoading();
        await Future.delayed(const Duration(milliseconds: 100));
        if (NetworkErrorHandler.isNetworkError(e)) {
          getIt<ToastificationService>().showToast('Network error');
        } else {
          getIt<ToastificationService>().showToast(
            getIt<AppLocalizations>().signUpFailed,
          );
        }
      }
    } else {
      getIt<LoadingService>().showGlobalLoading();
      try {
        QuerySnapshot querySnapshot =
            await userCollection
                .where('username', isEqualTo: username)
                .limit(1)
                .get();
        if (querySnapshot.docs.isNotEmpty) {
          getIt<LoadingService>().hideLoading();
          getIt<ToastificationService>().showToast(
            getIt<AppLocalizations>().userNameAlreadyExisted,
          );
          return;
        }
        final userModel = User(username: username, passcode: passcode);
        final user = await userCollection.add(userModel.toMap());
        getIt<CacheService>().setString(cacheKeyUsername, username);
        getIt<CacheService>().setBool(cacheKeyIsSignedIn, true);
        getIt<CacheService>().setString(cacheKeyUserId, user.id);
        await getIt<NotificationService>().init();
        getIt<LoadingService>().hideLoading();
        getIt<LoadingService>().showGlobalLoading(
          message: getIt<AppLocalizations>().createUserSuccess,
        );
        await Future.delayed(const Duration(seconds: 1));
        getIt<LoadingService>().hideLoading();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        getIt<LoadingService>().hideLoading();
        await Future.delayed(const Duration(milliseconds: 100));
        if (NetworkErrorHandler.isNetworkError(e)) {
          getIt<ToastificationService>().showToast('Network error');
        } else {
          getIt<ToastificationService>().showToast(
            getIt<AppLocalizations>().signUpFailed,
          );
        }
      }
    }
  }

  Future<User?> getUserByUsername(String username) async {
    if (getIt<CacheService>().getString(cacheKeyUsername) == username) {
      return null;
    }
    if (await NetworkErrorHandler.checkAndHandle()) return null;
    try {
      final userCollection = getIt<FirebaseFirestore>().collection('users');
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await userCollection
              .where('username', isEqualTo: username)
              .limit(1)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        return User.fromMap(querySnapshot.docs.first.data());
      } else {
        return null;
      }
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      }
      return null;
    }
  }

  Future<User?> getUserById(String userId) async {
    if (await NetworkErrorHandler.checkAndHandle()) return null;
    try {
      final userCollection = getIt<FirebaseFirestore>().collection('users');
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await userCollection.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return User.fromMap(doc.data()!);
      } else {
        return null;
      }
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      }
      return null;
    }
  }

  Future<String?> getDocIdByUsername(String targetUsername) async {
    if (await NetworkErrorHandler.checkAndHandle()) return null;
    try {
      QuerySnapshot querySnapshot =
          await getIt<FirebaseFirestore>()
              .collection('users')
              .where('username', isEqualTo: targetUsername)
              .limit(1)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      } else {
        debugPrint("No document found matching that username.");
        return null;
      }
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      }
      debugPrint("Error querying Firestore: $e");
      return null;
    }
  }

  Future<bool> updateUserNickName(
    String targetUsername,
    String nickName,
  ) async {
    if (await NetworkErrorHandler.checkAndHandle()) return false;
    try {
      final querySnapshot =
          await getIt<FirebaseFirestore>()
              .collection('users')
              .where('username', isEqualTo: targetUsername)
              .limit(1)
              .get();
      if (querySnapshot.docs.isEmpty) return false;
      await querySnapshot.docs.first.reference.update({
        'userNickName': nickName,
      });
      return true;
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      }
      return false;
    }
  }
}
