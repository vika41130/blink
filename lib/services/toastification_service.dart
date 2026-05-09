import 'package:blink/get_it_setup.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastificationService {
  showError(String errorMsg) {
    toastification.showCustom(
      alignment: Alignment.bottomCenter,
      autoCloseDuration: Duration(seconds: 2),
      builder: (context, item) {
        return Padding(
          padding: const EdgeInsets.all(appPadding),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(appBoxPadding),
            decoration: BoxDecoration(
              color: getIt<AppThemes>().themeData.colorScheme.primary,
              borderRadius: BorderRadius.circular(appBorderRadius),
            ),
            child: Text.rich(
              TextSpan(text: errorMsg),
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
