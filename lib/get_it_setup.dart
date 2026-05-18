import 'package:blink/app.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/chat_service.dart';
import 'package:blink/services/contact_service.dart';
import 'package:blink/services/loading_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> getItSetup() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  getIt.registerSingleton<CacheService>(CacheService());

  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<ToastificationService>(ToastificationService());
  getIt.registerSingleton<LoadingService>(LoadingService());
  getIt.registerSingleton<ChatService>(ChatService());
  getIt.registerSingleton<ContactService>(ContactService());

  getIt.registerSingleton<AppThemes>(AppThemes());

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
