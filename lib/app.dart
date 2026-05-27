import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/routes/routes_utils.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:blink/widgets/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BlinkApp extends StatelessWidget {
  const BlinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: RoutesUtils.onGenerateRoute,
        home: const SplashScreen(),
        theme: AppThemes.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
