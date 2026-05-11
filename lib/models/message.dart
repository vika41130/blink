import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String text;
  final DateTime timestamp;

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  // Factory to convert Firestore document data to MessageModel
  factory MessageModel.fromFirestore(Map<String, dynamic> data) {
    return MessageModel(
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert MessageModel back to a Map to save to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp':
          FieldValue.serverTimestamp(), // Always use server-side timestamp
    };
  }
}
