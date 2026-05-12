import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/auth_screen.dart';
import 'package:blink/widgets/qr_image_screen.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.qr_code_scanner),
          onPressed: () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => const QrImageScreen()),
            );
          },
        ),
        actions: [
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
              // Align(
              //   alignment: Alignment.center,
              //   child: QrImageView(
              //     data: getIt<CacheService>().getString(cacheKeyUserId) ?? '',
              //     version:
              //         QrVersions.auto, // Automatically calculate QR version
              //     size: 200.0, // Total width and height of the widget
              //     gapless: false, // Fixes alignment gaps on some screens
              //     dataModuleStyle: QrDataModuleStyle(
              //       color:
              //           Theme.of(
              //             context,
              //           ).colorScheme.primary, // Color of the QR code modules
              //     ),
              //     eyeStyle: QrEyeStyle(
              //       color: Theme.of(context).colorScheme.primary,
              //       eyeShape: QrEyeShape.square,
              //     ),
              //   ),
              // ),
              Text('List of contacts will be here'),
            ],
          ),
        ),
      ),
    );
  }
}
