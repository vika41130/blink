import 'package:blink/get_it_setup.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastificationService {
  showError(String msg) {
    toastification.showCustom(
      alignment: Alignment.bottomCenter,
      autoCloseDuration: Duration(seconds: 2),
      builder: (context, item) {
        return Padding(
          padding: const EdgeInsets.all(appPaddingSmall),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(appBoxPadding),
            decoration: BoxDecoration(
              color: getIt<AppThemes>().themeData.colorScheme.error,
              borderRadius: BorderRadius.circular(appBorderRadius),
            ),
            child: Text.rich(
              TextSpan(text: msg),
              style: TextStyle(
                color: getIt<AppThemes>().themeData.colorScheme.surfaceBright,
                fontSize: fontSizeSmall,
              ),
            ),
          ),
        );
      },
    );
  }

  showSuccess(String msg) {
    toastification.showCustom(
      alignment: Alignment.bottomCenter,
      autoCloseDuration: Duration(seconds: 2),
      builder: (context, item) {
        return Padding(
          padding: const EdgeInsets.all(appPaddingSmall),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(appBoxPadding),
            decoration: BoxDecoration(
              color: getIt<AppThemes>().themeData.colorScheme.primary,
              borderRadius: BorderRadius.circular(appBorderRadius),
            ),
            child: Text.rich(
              TextSpan(text: msg),
              style: TextStyle(
                color: getIt<AppThemes>().themeData.colorScheme.surfaceBright,
                fontSize: fontSizeSmall,
              ),
            ),
          ),
        );
      },
    );
  }
}
