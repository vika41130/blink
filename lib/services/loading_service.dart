import 'package:blink/app.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:flutter/material.dart';

class LoadingService {
  void showGlobalLoading({String message = ''}) {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder:
          (_) => Material(
            type: MaterialType.transparency,
            child: PopScope(
              canPop: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: appPaddingLarge),
                    message.isNotEmpty
                        ? Text(
                          message,
                          style: TextStyle(fontSize: fontSizeSmall),
                        )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void hideLoading() {
    navigatorKey.currentState?.pop();
  }
}
