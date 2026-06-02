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

  String? _currentChatReceiverId;

  void setCurrentChat(String? receiverId) {
    _currentChatReceiverId = receiverId;
  }

  Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _saveToken();
    _listenForegroundMessages();
    _listenTokenRefresh();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // Request Android 13+ notification permission
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
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
            builder: (_) => ChatScreen(
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
  }

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      final userId = getIt<CacheService>().getString(cacheKeyUserId);
      if (userId != null && userId.isNotEmpty) {
        await getIt<FirebaseFirestore>()
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
      }
    });
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground message received: ${message.data}');
      final senderId = message.data['senderId'];
      if (senderId == _currentChatReceiverId) return;

      final notification = message.notification;
      if (notification != null) {
        final title = notification.title ?? 'New message';
        final body = notification.body ?? '';
        final payload =
            '${message.data['receiverId']}|${message.data['senderId']}|${message.data['senderName']}';
        _showLocalNotification(title: title, body: body, payload: payload);
        _showInAppBanner(title: title, body: body, payload: payload);
      }
    });
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
        _onNotificationTap(NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: payload,
        ));
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
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the system notification tray automatically
}
