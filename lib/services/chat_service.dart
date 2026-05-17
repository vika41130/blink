import 'package:blink/get_it_setup.dart';
import 'package:blink/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  // Helper: Generate a unique chat room ID for 2 users (always sorted alphabetically)
  String getChatRoomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }

  // 1. Send Message
  Future<void> sendMessage({
    required String currentUserId,
    required String receiverId,
    required String messageText,
  }) async {
    if (messageText.trim().isEmpty) return;

    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    // Prepare message data
    final now = DateTime.now();
    final oneMinuteFromNow = now.add(const Duration(seconds: 10));
    final message = MessageModel(
      messageId: '',
      senderId: currentUserId,
      text: messageText.trim(),
      timestamp: now,
      createdAt: now,
      deleteAt: oneMinuteFromNow,
    );

    // Save message to nested subcollection
    await getIt<FirebaseFirestore>()
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toFirestore());

    // Update parent chat room document with metadata for chat list previews
    await getIt<FirebaseFirestore>().collection('chats').doc(chatRoomId).set({
      'participants': [currentUserId, receiverId],
      'lastMessage': messageText.trim(),
      'lastMessageSenderId': currentUserId,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 2. Stream Messages (Real-time read)
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
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // 3. Delete a message by setting its text to an empty string
  Future<void> deleteMessage({
    required String currentUserId,
    required String receiverId,
    required String messageId,
  }) async {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    await getIt<FirebaseFirestore>()
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}
