import 'dart:async';
import 'dart:io';
import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentChatReceiverId;
  bool _initialized = false;

  void setCurrentChat(String? receiverId) {
    _currentChatReceiverId = receiverId;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();
    await _initLocalNotifications();
    await _saveToken();
    _listenTokenRefresh();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Don't show if user is in the chat with the sender
      final senderId = message.data['senderId'];
      if (senderId == _currentChatReceiverId) return;
    });
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
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
  }

  Future<void> _saveToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(seconds: 2));
          final retryApns = await _messaging.getAPNSToken();
          if (retryApns == null) {
            debugPrint('APNs token not available');
            return;
          }
        }
      }
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM token: $token');
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

  void dispose() {}
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // notification payload from Cloud Function auto-displays on both platforms
  // no manual handling needed
}
