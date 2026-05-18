import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/models/contact.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContactService {
  Future<void> saveContact(String currentUserId, String username) async {
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

      // Check if username already exists in contacts
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

      // Add username to contacts
      await userDoc.update({
        'contacts': [...contacts, username],
      });

      getIt<ToastificationService>().showSuccess(
        getIt<AppLocalizations>().contactSavedSuccessfully,
      );
    } catch (e) {
      getIt<ToastificationService>().showError(
        getIt<AppLocalizations>().failedToSaveContact,
      );
      debugPrint('Error saving contact: $e');
    }
  }

  Future<void> removeContact(String currentUserId, String username) async {
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

      // Get current contacts
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

      // Remove username from contacts
      contacts.remove(username);
      await userDoc.update({'contacts': contacts});

      getIt<ToastificationService>().showSuccess(
        getIt<AppLocalizations>().contactRemovedSuccessfully,
      );
    } catch (e) {
      getIt<ToastificationService>().showError(
        getIt<AppLocalizations>().failedToSaveContact,
      );
      debugPrint('Error removing contact: $e');
    }
  }

  Future<bool> isContactAdded(String currentUserId, String username) async {
    if (currentUserId.isEmpty) {
      return false;
    }

    final userDoc = getIt<FirebaseFirestore>()
        .collection('users')
        .doc(currentUserId);

    final userSnapshot = await userDoc.get();
    final contacts =
        (userSnapshot.data()?['contacts'] as List<dynamic>?)?.cast<String>() ??
        [];

    return contacts.contains(username);
  }

  Future<List<Contact>> getContacts(String currentUserId) async {
    if (currentUserId.isEmpty) {
      return [];
    }

    try {
      final userDoc = getIt<FirebaseFirestore>()
          .collection('users')
          .doc(currentUserId);

      final userSnapshot = await userDoc.get();
      final contacts =
          (userSnapshot.data()?['contacts'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      if (contacts.isEmpty) {
        return [];
      }

      final List<Contact> contactEntries = [];
      for (final username in contacts) {
        final querySnapshot =
            await getIt<FirebaseFirestore>()
                .collection('users')
                .where('username', isEqualTo: username)
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          contactEntries.add(
            Contact.fromMap({
              'username': username,
              'userId': querySnapshot.docs.first.id,
            }),
          );
        }
      }

      return contactEntries;
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
      return [];
    }
  }
}
