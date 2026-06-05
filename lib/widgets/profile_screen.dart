import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/auth_screen.dart';
import 'package:blink/widgets/contact_screen.dart';
import 'package:blink/widgets/home_screen.dart';
import 'package:blink/widgets/qr_image_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents default back navigation
      onPopInvokedWithResult: (didPop, result) async {
        // safety check: if the system somehow already popped, don't repeat it
        if (didPop) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => const ContactScreen(),
                  ),
                );
              },
              icon: Icon(Icons.contact_page),
            ),
            IconButton(
              icon: Icon(Icons.power_settings_new),
              onPressed: () {
                getIt<CacheService>().clearCache();
                navigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: appPadding,
              right: appPadding,
              bottom: appPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    iconSize: appIconExtraLargeSize,
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: () {
                      navigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (context) => const QrImageScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: appFormItemMargin),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
