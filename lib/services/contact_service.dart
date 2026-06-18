import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/models/contact.dart';
import 'package:blink/services/network_error_handler.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContactService {
  List<String>? _cachedContacts;
  List<Contact>? _cachedContactModels;
  final ValueNotifier<int> contactsVersion = ValueNotifier(0);

  bool get hasCachedContacts => _cachedContactModels != null;

  Future<void> saveContact(String currentUserId, String username) async {
    if (await NetworkErrorHandler.checkAndHandle()) return;
    try {
      if (currentUserId.isEmpty) {
        getIt<ToastificationService>().showToast(
          getIt<AppLocalizations>().userNotFound,
        );
        return;
      }

      final userDoc = getIt<FirebaseFirestore>()
          .collection('users')
          .doc(currentUserId);

      final userSnapshot = await userDoc.get();
      final contacts =
          (userSnapshot.data()?['contacts'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      if (contacts.contains(username)) {
        getIt<ToastificationService>().showToast(
          getIt<AppLocalizations>().contactAlreadyAdded,
        );
        return;
      }

      await userDoc.update({
        'contacts': [...contacts, username],
      });

      // Add to cached contacts and maintain sort order
      if (_cachedContacts != null) {
        _cachedContacts!.add(username);
        _cachedContacts!.sort((a, b) => a.compareTo(b));
      }
      if (_cachedContactModels != null) {
        _cachedContactModels!.add(Contact(username: username));
        _cachedContactModels!.sort((a, b) => a.username.compareTo(b.username));
      }
      contactsVersion.value++;

      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().contactSavedSuccessfully,
      );
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      } else {
        getIt<ToastificationService>().showToast(
          getIt<AppLocalizations>().failedToSaveContact,
        );
        debugPrint('Error saving contact: $e');
      }
    }
  }

  Future<void> removeContact(String currentUserId, String username) async {
    if (await NetworkErrorHandler.checkAndHandle()) return;
    try {
      if (currentUserId.isEmpty) {
        getIt<ToastificationService>().showToast(
          getIt<AppLocalizations>().userNotFound,
        );
        return;
      }

      final userDoc = getIt<FirebaseFirestore>()
          .collection('users')
          .doc(currentUserId);

      final userSnapshot = await userDoc.get();
      final contacts =
          (userSnapshot.data()?['contacts'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      if (!contacts.contains(username)) {
        getIt<ToastificationService>().showToast(
          getIt<AppLocalizations>().contactNotAdded,
        );
        return;
      }

      contacts.remove(username);
      await userDoc.update({'contacts': contacts});

      // Remove from cached contacts
      _cachedContacts?.remove(username);
      _cachedContactModels?.removeWhere((c) => c.username == username);
      contactsVersion.value++;

      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().contactRemovedSuccessfully,
      );
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      } else {
        getIt<ToastificationService>().showToast(
          getIt<AppLocalizations>().failedToSaveContact,
        );
        debugPrint('Error removing contact: $e');
      }
    }
  }

  Future<bool> isContactAdded(String currentUserId, String username) async {
    if (currentUserId.isEmpty) return false;
    // Use cache if available
    if (_cachedContacts != null) {
      return _cachedContacts!.contains(username);
    }
    if (await NetworkErrorHandler.checkAndHandle()) return false;
    try {
      final userDoc = getIt<FirebaseFirestore>()
          .collection('users')
          .doc(currentUserId);

      final userSnapshot = await userDoc.get();
      final contacts =
          (userSnapshot.data()?['contacts'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      return contacts.contains(username);
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      }
      return false;
    }
  }

  Future<List<Contact>> getContacts({
    required String currentUserId,
    String searchText = '',
  }) async {
    if (currentUserId.isEmpty) return [];

    // Use cache if available and no search filter
    if (_cachedContactModels != null && searchText.isEmpty) {
      return List.from(_cachedContactModels!);
    }

    // If cache exists but searching, filter from cache
    if (_cachedContactModels != null && searchText.isNotEmpty) {
      return _cachedContactModels!
          .where(
            (c) =>
                c.username.toLowerCase().contains(searchText.toLowerCase()) ||
                c.userNickName.toLowerCase().contains(searchText.toLowerCase()),
          )
          .toList();
    }

    // If no cache, return empty — use loadContactsProgressively instead
    return [];
  }

  /// Loads contacts one by one, updating cache and notifying after each
  Future<void> loadContactsProgressively({
    required String currentUserId,
  }) async {
    if (currentUserId.isEmpty) return;
    if (_cachedContactModels != null) return; // already loaded

    if (await NetworkErrorHandler.checkAndHandle()) return;
    try {
      final userDoc = getIt<FirebaseFirestore>()
          .collection('users')
          .doc(currentUserId);
      final userSnapshot = await userDoc.get();
      List<String> contacts =
          (userSnapshot.data()?['contacts'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      if (contacts.isEmpty) {
        _cachedContacts = [];
        _cachedContactModels = [];
        return;
      }
      contacts.sort((a, b) => a.compareTo(b));
      _cachedContacts = List.from(contacts);
      _cachedContactModels = [];

      for (final username in contacts) {
        final querySnapshot =
            await getIt<FirebaseFirestore>()
                .collection('users')
                .where('username', isEqualTo: username)
                .limit(1)
                .get();
        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          _cachedContactModels!.add(
            Contact(
              username: username,
              userNickName: data['userNickName'] as String? ?? '',
            ),
          );
        } else {
          _cachedContactModels!.add(Contact(username: username));
        }
        // Notify after each contact is added
        contactsVersion.value++;
      }
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      }
      debugPrint('Error fetching contacts: $e');
    }
  }

  /// Update nickname in cache without re-fetching
  void updateNickNameInCache(String username, String newNickName) {
    if (_cachedContactModels == null) return;
    final index = _cachedContactModels!.indexWhere(
      (c) => c.username == username,
    );
    if (index != -1) {
      _cachedContactModels![index] = Contact(
        username: username,
        userNickName: newNickName,
      );
      contactsVersion.value++;
    }
  }

  /// Clear cached contacts on logout
  void clearCache() {
    _cachedContacts = null;
    _cachedContactModels = null;
  }
}
