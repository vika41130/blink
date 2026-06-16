import 'package:blink/get_it_setup.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastificationService {
  void showToast(String msg, {Duration? duration}) {
    toastification.showCustom(
      alignment: Alignment.center,
      autoCloseDuration: duration ?? const Duration(seconds: 2),
      builder: (context, item) {
        return Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: appBoxPadding * 2,
              vertical: appBoxPadding,
            ),
            decoration: BoxDecoration(
              color:
                  getIt<AppThemes>()
                      .themeData
                      .colorScheme
                      .surfaceContainerHighest,
              borderRadius: BorderRadius.circular(appBorderRadius * 4),
              border: Border.all(
                color: getIt<AppThemes>().themeData.colorScheme.secondary,
                width: smallBorderWidth,
              ),
            ),
            child: Text(
              msg,
              style: TextStyle(
                color: getIt<AppThemes>().themeData.colorScheme.primary,
                fontSize: fontSizeSmall,
              ),
            ),
          ),
        );
      },
    );
  }
}
