import 'dart:async';
import 'dart:io';
import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:blink/widgets/in_app_notification_banner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
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

  void _safeSetUnreadCount(int value) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unreadCount.value = value;
      });
    } else {
      unreadCount.value = value;
    }
  }

  void _syncUnreadCount() {
    final count = notifications.value.length;
    _safeSetUnreadCount(count);
    try {
      AppBadgePlus.updateBadge(count);
    } catch (_) {}
  }

  void resetCount() {
    // Count is driven by notifications.value.length, no manual reset needed
    try {
      _cleanExpiredNotifications();
    } catch (_) {}
  }

  void removeNotification(int index) {
    final list = [...notifications.value];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      notifications.value = list;
      _syncUnreadCount();
    }
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
    // Suppress foreground FCM messages (handled by Firestore listener)
    FirebaseMessaging.onMessage.listen((_) {});
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
      try {
        final userId = getIt<CacheService>().getString(cacheKeyUserId);
        if (userId != null && userId.isNotEmpty) {
          await getIt<FirebaseFirestore>()
              .collection('users')
              .doc(userId)
              .update({'fcmToken': token});
        }
      } catch (e) {
        debugPrint('Token refresh error: $e');
      }
    });
  }

  void _listenFirestoreMessages() {
    final userId = getIt<CacheService>().getString(cacheKeyUserId);
    if (userId == null || userId.isEmpty) return;

    bool isFirst = true;
    final Map<String, Timestamp?> lastNotifiedPerChat = {};
    _chatsSubscription = getIt<FirebaseFirestore>()
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen(
          (snapshot) {
            if (isFirst) {
              isFirst = false;
              // Record current state to avoid notifying for existing messages
              for (final doc in snapshot.docs) {
                final data = doc.data();
                final ts = data['lastMessageTimestamp'];
                lastNotifiedPerChat[doc.id] = ts is Timestamp ? ts : null;
              }
              return;
            }
            for (final change in snapshot.docChanges) {
              try {
                if (change.type == DocumentChangeType.modified) {
                  final data = change.doc.data();
                  if (data == null) continue;
                  final lastSenderId = data['lastMessageSenderId'] as String?;
                  final rawTimestamp = data['lastMessageTimestamp'];
                  final lastTimestamp =
                      rawTimestamp is Timestamp ? rawTimestamp : null;
                  // Skip if timestamp not yet resolved (server timestamp pending)
                  if (lastTimestamp == null) continue;
                  if (lastSenderId == null || lastSenderId.isEmpty) continue;
                  // Skip messages sent by current user
                  final currentUserId =
                      getIt<CacheService>().getString(cacheKeyUserId) ?? '';
                  if (lastSenderId == currentUserId) continue;
                  if (lastSenderId == _currentChatReceiverId) continue;

                  // Prevent duplicate: skip if already notified for this timestamp
                  final prevTimestamp = lastNotifiedPerChat[change.doc.id];
                  if (prevTimestamp != null &&
                      lastTimestamp.seconds == prevTimestamp.seconds &&
                      lastTimestamp.nanoseconds == prevTimestamp.nanoseconds) {
                    continue;
                  }
                  lastNotifiedPerChat[change.doc.id] = lastTimestamp;

                  // Skip past messages (older than 5 seconds)
                  final messageTime = lastTimestamp.toDate();
                  if (DateTime.now().difference(messageTime).inSeconds > 5) {
                    continue;
                  }

                  getIt<FirebaseFirestore>()
                      .collection('users')
                      .doc(lastSenderId)
                      .get()
                      .then((userDoc) {
                        final senderName =
                            userDoc.data()?['username'] ?? 'Someone';
                        final messageText =
                            data['lastMessage'] as String? ?? '';
                        final payload = '$userId|$lastSenderId|$senderName';
                        _notify(senderName, messageText, payload);
                      });
                }
              } catch (e) {
                debugPrint('Notification doc change error: $e');
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
      final item = NotificationItem(
        senderName: senderName,
        messageText: messageText,
        payload: payload,
        time: DateTime.now(),
      );
      // Remove expired notifications before adding new one
      final duration = Duration(
        minutes: getIt<CacheService>().getInt(cacheKeyChatMessageDuration) ?? 1,
      );
      final now = DateTime.now();
      final activeItems =
          notifications.value
              .where((n) => now.difference(n.time) < duration)
              .toList();
      notifications.value = [item, ...activeItems];
      _syncUnreadCount();
      _showInAppBanner(title: senderName, body: messageText, payload: payload);
      // Schedule cleanup
      Future.delayed(duration, () {
        _cleanExpiredNotifications();
      });
    } catch (e) {
      debugPrint('Notify error: $e');
    }
  }

  void _cleanExpiredNotifications() {
    try {
      final duration = Duration(
        minutes: getIt<CacheService>().getInt(cacheKeyChatMessageDuration) ?? 1,
      );
      final now = DateTime.now();
      final activeItems =
          notifications.value
              .where((n) => now.difference(n.time) < duration)
              .toList();
      if (activeItems.length != notifications.value.length) {
        notifications.value = activeItems;
        _syncUnreadCount();
      }
    } catch (_) {}
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
  // iOS: system notification is shown via APNs payload from Cloud Function
  // Android: show local notification here
  if (!Platform.isAndroid) return;

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
  const details = NotificationDetails(android: androidDetails);

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    senderName,
    'message',
    details,
    payload:
        '${message.data['receiverId']}|${message.data['senderId']}|$senderName',
  );
}
