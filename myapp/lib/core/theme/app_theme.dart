import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Plus Jakarta Sans';

  static final ThemeData lightTheme = _buildLightTheme();
  static final ThemeData darkTheme = _buildDarkTheme();

  static TextTheme _createTextTheme(TextTheme base) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: fontFamily,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.15,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontFamily: fontFamily,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontFamily: fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.2,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.25,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.3,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            height: 1.35,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.0,
            height: 1.4,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontFamily: fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        );
  }

  static ThemeData _buildLightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _createTextTheme(base.textTheme).apply(
      bodyColor: AppColors.foregroundLight,
      displayColor: AppColors.foregroundLight,
      fontFamily: fontFamily,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.cardLight,
        onSurface: AppColors.foregroundLight,
        error: AppColors.destructive,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: AppColors.borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.mutedForegroundLight,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foregroundLight,
          side: const BorderSide(color: AppColors.borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.foregroundLight),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _createTextTheme(base.textTheme).apply(
      bodyColor: AppColors.foregroundDark,
      displayColor: AppColors.foregroundDark,
      fontFamily: fontFamily,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.cardDark,
        onSurface: AppColors.foregroundDark,
        error: AppColors.destructive,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: AppColors.borderDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.mutedForegroundDark,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foregroundDark,
          side: const BorderSide(color: AppColors.borderDark),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: AppColors.foregroundDark),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

