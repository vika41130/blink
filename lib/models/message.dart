import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final String? imageBase64;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime deleteAt;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    this.imageBase64,
    required this.timestamp,
    required this.createdAt,
    required this.deleteAt,
  });

  bool get isImage => imageBase64 != null && imageBase64!.isNotEmpty;

  // Factory to convert Firestore document data to MessageModel
  factory MessageModel.fromFirestore(
    Map<String, dynamic> data,
    String messageId,
  ) {
    return MessageModel(
      messageId: messageId,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageBase64: data['imageBase64'],
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
      if (imageBase64 != null) 'imageBase64': imageBase64,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'deleteAt': Timestamp.fromDate(deleteAt),
    };
  }
}
