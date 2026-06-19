import 'dart:convert';
import 'dart:io';

import 'package:blink/get_it_setup.dart';
import 'package:blink/models/message.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/network_error_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  String getChatRoomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }

  Future<DateTime?> getLastChatTime(
    String currentUserId,
    String contactUsername,
  ) async {
    if (await NetworkErrorHandler.checkAndHandle()) return null;
    try {
      final querySnapshot =
          await getIt<FirebaseFirestore>()
              .collection('users')
              .where('username', isEqualTo: contactUsername)
              .limit(1)
              .get();
      if (querySnapshot.docs.isEmpty) return null;
      final contactUserId = querySnapshot.docs.first.id;

      final chatRoomId = getChatRoomId(currentUserId, contactUserId);
      final doc =
          await getIt<FirebaseFirestore>()
              .collection('chats')
              .doc(chatRoomId)
              .get();
      if (!doc.exists) return null;
      final timestamp = doc.data()?['lastMessageTimestamp'] as Timestamp?;
      return timestamp?.toDate();
    } catch (_) {
      return null;
    }
  }

  Future<void> sendMessage({
    required String currentUserId,
    required String receiverId,
    required String messageText,
  }) async {
    if (messageText.trim().isEmpty) return;
    if (await NetworkErrorHandler.checkAndHandle()) return;

    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    int durationMinutes =
        getIt<CacheService>().getInt(cacheKeyChatMessageDuration) ?? 1;

    final now = DateTime.now();
    final deleteAt = now.add(Duration(minutes: durationMinutes));
    final message = MessageModel(
      messageId: '',
      senderId: currentUserId,
      text: messageText.trim(),
      timestamp: now,
      createdAt: now,
      deleteAt: deleteAt,
    );

    try {
      await getIt<FirebaseFirestore>()
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toFirestore());

      await getIt<FirebaseFirestore>().collection('chats').doc(chatRoomId).set({
        'participants': [currentUserId, receiverId],
        'lastMessage': messageText.trim(),
        'lastMessageSenderId': currentUserId,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      }
    }
  }

  Future<void> sendImageMessage({
    required String currentUserId,
    required String receiverId,
    required File imageFile,
  }) async {
    if (await NetworkErrorHandler.checkAndHandle()) return;

    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    try {
      // Convert image to base64 binary string
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      int durationMinutes =
          getIt<CacheService>().getInt(cacheKeyChatMessageDuration) ?? 1;

      final now = DateTime.now();
      final deleteAt = now.add(Duration(minutes: durationMinutes));

      final message = MessageModel(
        messageId: '',
        senderId: currentUserId,
        text: '',
        imageBase64: base64Image,
        timestamp: now,
        createdAt: now,
        deleteAt: deleteAt,
      );

      await getIt<FirebaseFirestore>()
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toFirestore());

      await getIt<FirebaseFirestore>().collection('chats').doc(chatRoomId).set({
        'participants': [currentUserId, receiverId],
        'lastMessage': '📷 Photo',
        'lastMessageSenderId': currentUserId,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      }
    }
  }

  Stream<List<MessageModel>> getMessages(String user1, String user2) {
    final currentTime = Timestamp.fromDate(DateTime.now());
    final String chatRoomId = getChatRoomId(user1, user2);
    return getIt<FirebaseFirestore>()
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .where('deleteAt', isGreaterThan: currentTime)
        .orderBy('deleteAt', descending: true)
        .snapshots()
        .handleError((e) {
          if (NetworkErrorHandler.isNetworkError(e)) {
            NetworkErrorHandler.handleNetworkError();
          }
        })
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> deleteMessage({
    required String currentUserId,
    required String receiverId,
    required String messageId,
  }) async {
    if (await NetworkErrorHandler.checkAndHandle()) return;

    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    try {
      await getIt<FirebaseFirestore>()
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      }
    }
  }

  Future<void> setTypingStatus({
    required String currentUserId,
    required String receiverId,
    required bool isTyping,
  }) async {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    try {
      await getIt<FirebaseFirestore>().collection('chats').doc(chatRoomId).set({
        'typing_$currentUserId': isTyping,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Stream<bool> getTypingStatus({
    required String currentUserId,
    required String receiverId,
  }) {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    return getIt<FirebaseFirestore>()
        .collection('chats')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          final data = snapshot.data();
          return data?['typing_$receiverId'] == true;
        })
        .distinct();
  }

  /// Stream that emits true if the chat is blocked by either user.
  Stream<bool> chatBlockedStream({
    required String currentUserId,
    required String receiverId,
  }) {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    return getIt<FirebaseFirestore>()
        .collection('chats')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          final data = snapshot.data();
          return data?['blocked_$currentUserId'] == true ||
              data?['blocked_$receiverId'] == true;
        })
        .distinct();
  }

  Future<bool> isChatBlocked({
    required String currentUserId,
    required String receiverId,
  }) async {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    try {
      final doc =
          await getIt<FirebaseFirestore>()
              .collection('chats')
              .doc(chatRoomId)
              .get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['blocked_$currentUserId'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setChatBlocked({
    required String currentUserId,
    required String receiverId,
    required bool isBlocked,
  }) async {
    if (await NetworkErrorHandler.checkAndHandle()) return false;
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    try {
      await getIt<FirebaseFirestore>().collection('chats').doc(chatRoomId).set({
        'blocked_$currentUserId': isBlocked,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      if (NetworkErrorHandler.isNetworkError(e)) {
        await NetworkErrorHandler.handleNetworkError();
      }
      return false;
    }
  }
}
