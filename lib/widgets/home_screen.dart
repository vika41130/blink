import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/auth_screen.dart';
import 'package:blink/widgets/home_content.dart';
import 'package:blink/widgets/profile_content.dart';
import 'package:blink/widgets/qr_scanner_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget content = const HomeContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getIt<AppLocalizations>().homeTitle,
          style: TextStyle(
            fontSize: appTitleFontSize,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
              Row(children: [Expanded(child: content)]),
            ],
          ),
        ),
      ),
      // stop here
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home_filled),
              onPressed: () {
                setState(() {
                  content = const HomeContent();
                });
              },
            ),
            IconButton(icon: Icon(Icons.qr_code_scanner), onPressed: () {
              navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (context) => const QRScannerScreen()),
              );
            }),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                setState(() {
                  content = const ProfileContent();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
