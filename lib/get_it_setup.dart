import 'package:blink/app.dart';
import 'package:blink/firebase_options.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/chat_list_service.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/services/loading_service.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

void getItSetupSync(SharedPreferences sharedPreferences) {
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  getIt.registerSingleton<CacheService>(CacheService());
  getIt.registerSingleton<AppThemes>(AppThemes());
  getIt.registerSingleton<ToastificationService>(ToastificationService());
  getIt.registerSingleton<LoadingService>(LoadingService());

  getIt.registerFactory<AppLocalizations>(() {
    final context = navigatorKey.currentContext;
    if (context == null) {
      throw Exception(
        "Navigator context is null. Ensure the app is fully initialized.",
      );
    }
    return AppLocalizations.of(context)!;
  });
}

Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final firestore = FirebaseFirestore.instance;
  firestore.settings = const Settings(persistenceEnabled: false);
  getIt.registerSingleton<FirebaseFirestore>(firestore);
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<NotificationService>(NotificationService());
  getIt.registerSingleton<ChatListService>(ChatListService());
  getIt.registerLazySingleton<ChatService>(() => ChatService());
  getIt.registerLazySingleton<ContactService>(() => ContactService());
}
