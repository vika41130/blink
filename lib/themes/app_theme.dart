import 'package:flutter/material.dart';

class AppThemes {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.blue, // Your primary color
    appBarTheme: const AppBarTheme(elevation: 0),
    extensions: <ThemeExtension<dynamic>>[
      const AppColors(
        success: Color.fromARGB(255, 49, 206, 175),
        error: Color.fromARGB(255, 240, 99, 83),
      ),
    ],
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.indigo,
    extensions: <ThemeExtension<dynamic>>[
      const AppColors(
        success: Color.fromARGB(255, 215, 102, 241),
        error: Color.fromARGB(255, 233, 122, 159),
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
