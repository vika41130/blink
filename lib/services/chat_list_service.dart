import 'dart:async';

import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

class ChatRoom {
  final String receiverId;
  final String receiverName;
  final String displayName;
  final String lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastTimestamp;

  ChatRoom({
    required this.receiverId,
    required this.receiverName,
    required this.displayName,
    required this.lastMessage,
    this.lastMessageSenderId,
    this.lastTimestamp,
  });
}

class ChatListService {
  final ValueNotifier<List<ChatRoom>> chatRooms = ValueNotifier<List<ChatRoom>>(
    [],
  );
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  StreamSubscription? _subscription;
  bool _listening = false;
  bool _isViewingChatList = false;

  /// Track the last known timestamps per chat room to detect new messages.
  final Map<String, DateTime> _lastKnownTimestamps = {};
  bool _firstSnapshot = true;

  void setViewingChatList(bool viewing) {
    _isViewingChatList = viewing;
    if (viewing && unreadCount.value != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unreadCount.value = 0;
      });
    }
  }

  void resetCount() {
    unreadCount.value = 0;
  }

  /// Start a real-time listener that keeps the chat list updated.
  void startListening() {
    if (_listening) return;

    final currentUserId = getIt<CacheService>().getString(cacheKeyUserId) ?? '';
    if (currentUserId.isEmpty) return;

    _listening = true;
    _firstSnapshot = true;

    _subscription = getIt<FirebaseFirestore>()
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) => _processSnapshot(snapshot, currentUserId));
  }

  Future<void> _processSnapshot(
    QuerySnapshot snapshot,
    String currentUserId,
  ) async {
    try {
      final List<ChatRoom> rooms = [];

      for (final doc in snapshot.docs) {
        final rawData = doc.data();
        if (rawData == null || rawData is! Map<String, dynamic>) continue;
        final data = rawData;

        final lastMessage = data['lastMessage'] as String? ?? '';
        final lastTimestamp = data['lastMessageTimestamp'] as Timestamp?;
        final lastMessageSenderId =
            data['lastMessageSenderId'] as String? ?? '';

        // Skip chats with no messages
        if (lastMessage.isEmpty && lastTimestamp == null) continue;

        final participantsRaw = data['participants'];
        if (participantsRaw == null || participantsRaw is! List) continue;
        final participants = List<String>.from(participantsRaw);
        final receiverId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        if (receiverId.isEmpty) continue;

        // Detect new incoming messages (not from current user)
        if (!_firstSnapshot &&
            !_isViewingChatList &&
            lastTimestamp != null &&
            lastMessageSenderId.isNotEmpty &&
            lastMessageSenderId != currentUserId) {
          final ts = lastTimestamp.toDate();
          final previousTs = _lastKnownTimestamps[doc.id];
          if (previousTs == null || ts.isAfter(previousTs)) {
            unreadCount.value++;
          }
        }

        // Update known timestamp
        if (lastTimestamp != null) {
          _lastKnownTimestamps[doc.id] = lastTimestamp.toDate();
        }

        // Get receiver's username
        String receiverName = '';
        String displayName = '';
        try {
          final userDoc =
              await getIt<FirebaseFirestore>()
                  .collection('users')
                  .doc(receiverId)
                  .get();
          receiverName = userDoc.data()?['username'] as String? ?? '';
          displayName = userDoc.data()?['userNickName'] as String? ?? '';
        } catch (_) {}

        rooms.add(
          ChatRoom(
            receiverId: receiverId,
            receiverName: receiverName,
            displayName: displayName.isNotEmpty ? displayName : receiverName,
            lastMessage: lastMessage,
            lastMessageSenderId: lastMessageSenderId,
            lastTimestamp: lastTimestamp?.toDate(),
          ),
        );
      }

      rooms.sort((a, b) {
        if (a.lastTimestamp == null && b.lastTimestamp == null) return 0;
        if (a.lastTimestamp == null) return 1;
        if (b.lastTimestamp == null) return -1;
        return b.lastTimestamp!.compareTo(a.lastTimestamp!);
      });

      chatRooms.value = rooms;
      _firstSnapshot = false;
    } catch (e) {
      debugPrint('ChatListService error: $e');
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _listening = false;
  }

  void clear() {
    stopListening();
    chatRooms.value = [];
    unreadCount.value = 0;
    _lastKnownTimestamps.clear();
    _firstSnapshot = true;
  }
}
