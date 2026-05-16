import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime deleteAt;

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.createdAt,
    required this.deleteAt,
  });

  // Factory to convert Firestore document data to MessageModel
  factory MessageModel.fromFirestore(Map<String, dynamic> data) {
    return MessageModel(
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deleteAt:
          (data['deleteAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(minutes: 1)),
    );
  }

  // Convert MessageModel back to a Map to save to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'deleteAt': Timestamp.fromDate(deleteAt),
    };
  }
}
