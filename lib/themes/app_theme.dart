import 'package:blink/settings/fixed_settings.dart';
import 'package:flutter/material.dart';

const _darkBlue700 = Color(0xFF1B3A5C);
const _darkBlue500 = Color(0xFF2E6399);
const _darkBlue400 = Color(0xFF3D7AB8);
const _darkBlue200 = Color(0xFF8BBAE8);
const _darkBlue100 = Color(0xFFB8D4F0);

class AppThemes {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'monospace',
    colorScheme: ColorScheme.light(
      primary: _darkBlue700,
      secondary: _darkBlue500,
      tertiary: _darkBlue400,
      error: const Color(0xFFD32F2F),
      surface: _darkBlue100,
      surfaceContainerHighest: _darkBlue200,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: _darkBlue700, size: appBarIconSize),
      titleSpacing: appPaddingSmall,
    ),
    extensions: <ThemeExtension<dynamic>>[
      const AppColors(success: Color(0xFF2E7D6E), error: Color(0xFFD32F2F)),
    ],
  );

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
    extensions: <ThemeExtension<dynamic>>[
      const AppColors(success: Color(0xFF4DB6AC), error: Color(0xFFEF5350)),
    ],
  );

  bool isDarkMode = true;

  ThemeData get themeData => isDarkMode ? darkTheme : lightTheme;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
  }
}

class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color error;

  const AppColors({required this.success, required this.error});

  @override
  AppColors copyWith({Color? success, Color? error}) {
    return AppColors(
      success: success ?? this.success,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
