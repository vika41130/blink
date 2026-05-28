import 'package:flutter/material.dart';

const _darkBlue900 = Color(0xFF0D1B2A);
const _darkBlue800 = Color(0xFF1B2838);
const _darkBlue700 = Color(0xFF1B3A5C);
const _darkBlue500 = Color(0xFF2E6399);
const _darkBlue400 = Color(0xFF3D7AB8);
const _darkBlue300 = Color(0xFF5C9AD6);
const _darkBlue200 = Color(0xFF8BBAE8);
const _darkBlue100 = Color(0xFFB8D4F0);

class AppThemes {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
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
      iconTheme: IconThemeData(color: _darkBlue700),
    ),
    extensions: <ThemeExtension<dynamic>>[
      const AppColors(
        success: Color(0xFF2E7D6E),
        error: Color(0xFFD32F2F),
      ),
    ],
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _darkBlue300,
      secondary: _darkBlue400,
      tertiary: _darkBlue200,
      error: const Color(0xFFEF5350),
      surface: _darkBlue900,
      surfaceContainerHighest: _darkBlue800,
      onSurface: _darkBlue100,
      onSurfaceVariant: _darkBlue200,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      iconTheme: IconThemeData(color: _darkBlue300),
    ),
    extensions: <ThemeExtension<dynamic>>[
      const AppColors(
        success: Color(0xFF4DB6AC),
        error: Color(0xFFEF5350),
      ),
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
