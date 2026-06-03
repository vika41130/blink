import 'dart:async';
import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:blink/widgets/in_app_notification_banner.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<List<NotificationItem>> notifications =
      ValueNotifier<List<NotificationItem>>([]);

  String? _currentChatReceiverId;
  StreamSubscription? _chatsSubscription;

  void resetCount() {
    unreadCount.value = 0;
    AppBadgePlus.updateBadge(0);
  }

  void removeNotification(int index) {
    final list = [...notifications.value];
    list.removeAt(index);
    notifications.value = list;
  }

  void setCurrentChat(String? receiverId) {
    _currentChatReceiverId = receiverId;
  }

  Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _saveToken();
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

  void _listenFirestoreMessages() {
    final userId = getIt<CacheService>().getString(cacheKeyUserId);
    if (userId == null || userId.isEmpty) return;

    bool isFirst = true;
    _chatsSubscription = getIt<FirebaseFirestore>()
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen(
          (snapshot) {
            if (isFirst) {
              isFirst = false;
              return;
            }
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.modified) {
                final data = change.doc.data();
                if (data == null) continue;
                final lastSenderId = data['lastMessageSenderId'] as String?;
                if (lastSenderId == null || lastSenderId == userId) continue;
                if (lastSenderId == _currentChatReceiverId) continue;

                getIt<FirebaseFirestore>()
                    .collection('users')
                    .doc(lastSenderId)
                    .get()
                    .then((userDoc) {
                      final senderName =
                          userDoc.data()?['username'] ?? 'Someone';
                      final messageText = data['lastMessage'] as String? ?? '';
                      final payload = '$userId|$lastSenderId|$senderName';
                      _notify(senderName, messageText, payload);
                    });
              }
            }
          },
          onError: (e) {
            debugPrint('Chat listener error: $e');
          },
        );
  }

  void _notify(String senderName, String messageText, String payload) {
    try {
      unreadCount.value++;
      AppBadgePlus.updateBadge(unreadCount.value);
      final item = NotificationItem(
        senderName: senderName,
        messageText: messageText,
        payload: payload,
        time: DateTime.now(),
      );
      notifications.value = [item, ...notifications.value];
      _showInAppBanner(title: senderName, body: messageText, payload: payload);
      Future.delayed(
        const Duration(seconds: notificationAutoDeleteSeconds),
        () {
          final list = [...notifications.value];
          list.remove(item);
          notifications.value = list;
        },
      );
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

  void dispose() {
    _chatsSubscription?.cancel();
  }
}

class NotificationItem {
  final String senderName;
  final String messageText;
  final String payload;
  final DateTime time;

  NotificationItem({
    required this.senderName,
    required this.messageText,
    required this.payload,
    required this.time,
  });
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
