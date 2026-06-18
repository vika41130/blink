import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/auth_screen.dart';
import 'package:blink/widgets/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _init();
  }

  Future<void> _init() async {
    try {
      final minDuration = Future.delayed(const Duration(milliseconds: 1500));
      if (!getIt.isRegistered<CacheService>()) {
        final sp = await SharedPreferences.getInstance();
        getItSetupSync(sp);
      }
      if (!getIt.isRegistered<bool>(instanceName: 'firebaseReady')) {
        await initFirebase();
        getIt.registerSingleton<bool>(true, instanceName: 'firebaseReady');
      }
      await minDuration;
      if (!mounted) return;
      final isSignedIn = getIt<CacheService>().getBool(cacheKeyIsSignedIn);
      if (isSignedIn) {
        await getIt<NotificationService>().init();
      }
      final destination = isSignedIn ? const HomeScreen() : const AuthScreen();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: appIconHugeSize),
              const SizedBox(height: appFormItemMargin),
              const Text('Network error. Please check your connection.'),
              const SizedBox(height: appFormItemMargin),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = false);
                  _init();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Icon(
            Icons.bolt,
            size: appIconHugeSize * 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
