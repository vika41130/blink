import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/network_error_handler.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContactService {
  List<String>? _cachedContacts;
  final ValueNotifier<int> contactsVersion = ValueNotifier(0);

  Future<void> saveContact(String currentUserId, String username) async {
    if (await NetworkErrorHandler.checkAndHandle()) return;
    try {
      if (currentUserId.isEmpty) {
        getIt<ToastificationService>().showError(
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
        getIt<ToastificationService>().showError(
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
      contactsVersion.value++;

      getIt<ToastificationService>().showSuccess(
        getIt<AppLocalizations>().contactSavedSuccessfully,
      );
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      } else {
        getIt<ToastificationService>().showError(
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
        getIt<ToastificationService>().showError(
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
        getIt<ToastificationService>().showError(
          getIt<AppLocalizations>().contactNotAdded,
        );
        return;
      }

      contacts.remove(username);
      await userDoc.update({'contacts': contacts});

      // Remove from cached contacts
      _cachedContacts?.remove(username);
      contactsVersion.value++;

      getIt<ToastificationService>().showSuccess(
        getIt<AppLocalizations>().contactRemovedSuccessfully,
      );
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      } else {
        getIt<ToastificationService>().showError(
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

  Future<List<String>> getContacts({
    required String currentUserId,
    String searchText = '',
  }) async {
    if (currentUserId.isEmpty) return [];

    // Use cache if available and no search filter
    if (_cachedContacts != null && searchText.isEmpty) {
      return List.from(_cachedContacts!);
    }

    // If cache exists but searching, filter from cache
    if (_cachedContacts != null && searchText.isNotEmpty) {
      return _cachedContacts!
          .where(
            (username) =>
                username.toLowerCase().contains(searchText.toLowerCase()),
          )
          .toList();
    }

    if (await NetworkErrorHandler.checkAndHandle()) return [];
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
        return [];
      }
      contacts.sort((a, b) => a.compareTo(b));

      // Cache the contacts
      _cachedContacts = List.from(contacts);

      if (searchText.isNotEmpty) {
        contacts =
            contacts
                .where(
                  (username) =>
                      username.toLowerCase().contains(searchText.toLowerCase()),
                )
                .toList();
      }
      return contacts;
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      }
      debugPrint('Error fetching contacts: $e');
      return [];
    }
  }

  /// Clear cached contacts on logout
  void clearCache() {
    _cachedContacts = null;
  }
}
