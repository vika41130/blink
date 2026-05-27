import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/auth_screen.dart';
import 'package:blink/widgets/home_screen.dart';
import 'package:blink/widgets/splash_screen.dart';
import 'package:flutter/material.dart';

class RoutesUtils {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (context) => const SplashScreen());
      case auth:
        return MaterialPageRoute(builder: (context) => AuthScreen());
      case home:
        return MaterialPageRoute(builder: (context) => HomeScreen());
      default:
        return MaterialPageRoute(
          builder:
              (context) =>
                  Scaffold(body: Center(child: Text('No route found'))),
        );
    }
  }
}
