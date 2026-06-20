import 'dart:convert';

import 'package:blink/get_it_setup.dart';
import 'package:blink/models/user.dart';
import 'package:blink/services/contact_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  bool getBool(String key) => getIt<SharedPreferences>().getBool(key) ?? false;
  Future<void> setBool(String key, bool value) =>
      getIt<SharedPreferences>().setBool(key, value);

  String? getString(String key) => getIt<SharedPreferences>().getString(key);
  Future<void> setString(String key, String value) =>
      getIt<SharedPreferences>().setString(key, value);

  int? getInt(String key) => getIt<SharedPreferences>().getInt(key);
  Future<void> setInt(String key, int value) =>
      getIt<SharedPreferences>().setInt(key, value);

  void cacheUser(User user) {
    setString(cacheKeyUsername, user.username);
    setString(cacheKeyUserPin, user.pin);
    setString(cacheKeyUserNickName, user.userNickName);
    setString(cacheKeyUserContacts, jsonEncode(user.contacts));
    setInt(cacheKeyChatMessageDuration, user.chatMessageDuration);
    setBool(cacheKeyContactsLocked, user.contactsLocked);
  }

  void clearCache() {
    setString(cacheKeyUsername, '');
    setBool(cacheKeyIsSignedIn, false);
    setString(cacheKeyUserId, '');
    setString('lastPinVerified', '');
    setString('pincodeDurationMinutes', '');
    setBool(cacheKeyPinVerificationEnabled, true);
    setBool(cacheKeyContactsLocked, false);
    setString(cacheKeyVerificationCode, '');
    setString(cacheKeyVerificationExpiry, '');
    setString(cacheKeyPendingEmail, '');
    setString(cacheKeyUserPin, '');
    setString(cacheKeyUserNickName, '');
    setString(cacheKeyUserContacts, '');
    setInt(cacheKeyChatMessageDuration, 1);
    setString('chatMessageDurationMinutes', '');
    getIt<ContactService>().clearCache();
  }
}

const cacheKeyUsername = 'blinkCacheKeyUsername';
const cacheKeyIsSignedIn = 'blinkCacheKeyIsSignedIn';
const cacheKeyUserId = 'cacheKeyUserId';
const cacheKeyPinVerificationEnabled = 'pinVerificationEnabled';
const cacheKeyUserPin = 'cacheKeyUserPin';
const cacheKeyUserNickName = 'cacheKeyUserNickName';
const cacheKeyUserContacts = 'cacheKeyUserContacts';
const cacheKeyChatMessageDuration = 'cacheKeyChatMessageDuration';
const cacheKeyContactsLocked = 'cacheKeyContactsLocked';
const cacheKeyVerificationCode = 'cacheKeyVerificationCode';
const cacheKeyVerificationExpiry = 'cacheKeyVerificationExpiry';
const cacheKeyPendingEmail = 'cacheKeyPendingEmail';
