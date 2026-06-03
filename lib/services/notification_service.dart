import 'dart:async';
import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:blink/widgets/in_app_notification_banner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  String? _currentChatReceiverId;
  StreamSubscription? _chatsSubscription;
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  void resetCount() {
    unreadCount.value = 0;
  }

  void setCurrentChat(String? receiverId) {
    _currentChatReceiverId = receiverId;
  }

  Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _saveToken();
    _listenForegroundMessages();
    _listenTokenRefresh();
    _listenFirestoreMessages();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'chat_messages',
        'Chat Messages',
        importance: Importance.high,
      ),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      final parts = payload.split('|');
      if (parts.length == 3) {
        final currentUserId = parts[0];
        final senderId = parts[1];
        final senderName = parts[2];
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder:
                (_) => ChatScreen(
                  currentUserId: currentUserId,
                  receiverId: senderId,
                  receiverName: senderName,
                ),
          ),
        );
      }
    }
  }

  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final userId = getIt<CacheService>().getString(cacheKeyUserId);
        if (userId != null && userId.isNotEmpty) {
          await getIt<FirebaseFirestore>()
              .collection('users')
              .doc(userId)
              .update({'fcmToken': token});
        }
      }
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      final userId = getIt<CacheService>().getString(cacheKeyUserId);
      if (userId != null && userId.isNotEmpty) {
        await getIt<FirebaseFirestore>().collection('users').doc(userId).update(
          {'fcmToken': token},
        );
      }
    });
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final senderId = message.data['senderId'];
      if (senderId == _currentChatReceiverId) return;

      final senderName = message.data['senderName'] ?? 'Someone';
      final payload = '${message.data['receiverId']}|$senderId|$senderName';
      _notify(senderName, payload);
    });
  }

  void _listenFirestoreMessages() {
    final userId = getIt<CacheService>().getString(cacheKeyUserId);
    if (userId == null || userId.isEmpty) return;

    _chatsSubscription = getIt<FirebaseFirestore>()
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen(
          (snapshot) {
            for (final doc in snapshot.docs) {
              final chatRoomId = doc.id;
              if (_messageSubscriptions.containsKey(chatRoomId)) continue;

              bool isFirst = true;
              _messageSubscriptions[chatRoomId] = getIt<FirebaseFirestore>()
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .snapshots()
                  .listen(
                    (msgSnapshot) {
                      if (isFirst) {
                        isFirst = false;
                        return;
                      }
                      for (final change in msgSnapshot.docChanges) {
                        if (change.type == DocumentChangeType.added) {
                          final data = change.doc.data();
                          if (data == null) continue;
                          final senderId = data['senderId'] as String?;
                          if (senderId == null || senderId == userId) continue;
                          if (senderId == _currentChatReceiverId) continue;

                          getIt<FirebaseFirestore>()
                              .collection('users')
                              .doc(senderId)
                              .get()
                              .then((userDoc) {
                                final senderName =
                                    userDoc.data()?['username'] ?? 'Someone';
                                final payload = '$userId|$senderId|$senderName';
                                _notify(senderName, payload);
                              });
                        }
                      }
                    },
                    onError: (e) {
                      debugPrint('Message listener error: $e');
                    },
                  );
            }
          },
          onError: (e) {
            debugPrint('Chat listener error: $e');
          },
        );
  }

  void _notify(String senderName, String payload) {
    try {
      unreadCount.value++;
      _showInAppBanner(title: senderName, body: 'message', payload: payload);
    } catch (e) {
      debugPrint('Notify error: $e');
    }
  }

  void _showInAppBanner({
    required String title,
    required String body,
    String? payload,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    showOverlay(context, title, body, () {
      if (payload != null) {
        final parts = payload.split('|');
        if (parts.length == 3) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder:
                  (_) => ChatScreen(
                    currentUserId: parts[0],
                    receiverId: parts[1],
                    receiverName: parts[2],
                  ),
            ),
          );
        }
      }
    });
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void dispose() {
    _chatsSubscription?.cancel();
    for (final sub in _messageSubscriptions.values) {
      sub.cancel();
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings);

  final senderName = message.data['senderName'] ?? 'Someone';

  const androidDetails = AndroidNotificationDetails(
    'chat_messages',
    'Chat Messages',
    importance: Importance.high,
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails();
  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    '',
    'message',
    details,
    payload:
        '${message.data['receiverId']}|${message.data['senderId']}|$senderName',
  );
}
