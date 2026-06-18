import 'package:blink/settings/fixed_settings.dart';
import 'package:flutter/material.dart';

class AppThemes {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'monospace',
    scaffoldBackgroundColor: const Color(0xFF000000),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFFFFFFFF),
      secondary: const Color(0xFFFFFFFF),
      tertiary: const Color(0xFFFFFFFF),
      error: const Color(0xFFFFFFFF),
      surface: const Color(0xFF000000),
      surfaceContainerHighest: const Color(0xFF1A1A1A),
      surfaceBright: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFFFFFFFF),
      onSurfaceVariant: const Color(0xFFFFFFFF),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: const Color(0xFF000000),
      iconTheme: IconThemeData(
        color: const Color(0xFFFFFFFF),
        size: appBarIconSize,
      ),
      titleSpacing: appPaddingSmall,
    ),
    bottomAppBarTheme: const BottomAppBarTheme(color: Color(0xFF000000)),
    iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
  );

  ThemeData get themeData => darkTheme;
}
