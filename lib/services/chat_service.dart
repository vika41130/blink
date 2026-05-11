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
    final message = MessageModel(
      senderId: currentUserId,
      text: messageText.trim(),
      timestamp: DateTime.now(),
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
    final String chatRoomId = getChatRoomId(user1, user2);
    return getIt<FirebaseFirestore>()
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy(
          'timestamp',
          descending: true,
        ) // Newest messages first for easy ListView implementation
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromFirestore(doc.data());
          }).toList();
        });
  }
}
