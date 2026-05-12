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

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    if (getIt<CacheService>().getString(cacheKeyUsername) == username) {
      return null;
    }
    try {
      final userCollection = getIt<FirebaseFirestore>().collection('users');
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await userCollection
              .where('username', isEqualTo: username)
              .limit(1)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final userCollection = getIt<FirebaseFirestore>().collection('users');
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await userCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> getDocIdByUsername(String targetUsername) async {
    try {
      // 1. Create a query looking for the matching field value
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: targetUsername)
              .limit(1) // Optimization: stop searching after the first match
              .get();

      // 2. Check if any matching document was actually found
      if (querySnapshot.docs.isNotEmpty) {
        // 3. Extract the document ID from the snapshot metadata
        String docId = querySnapshot.docs.first.id;
        return docId;
      } else {
        print("No document found matching that username.");
        return null;
      }
    } catch (e) {
      print("Error querying Firestore: $e");
      return null;
    }
  }
}
