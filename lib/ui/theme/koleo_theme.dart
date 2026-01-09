import 'dart:ui';
import 'package:flutter/material.dart';
import 'koleo_colors.dart';
import 'koleo_typography.dart';

/// Тема приложения Koleo Browser
class KoleoTheme {
  KoleoTheme._();

  // Blur and transparency settings (from design spec)
  static const double addressBarBlur = 20.0;
  static const double tabBarBlur = 15.0;
  static const double dialogBlur = 25.0;

  // Animation durations (from design spec)
  static const Duration screenTransition = Duration(milliseconds: 300);
  static const Duration elementAppear = Duration(milliseconds: 200);
  static const Duration hoverEffect = Duration(milliseconds: 150);

  // Animation curves
  static const Curve screenTransitionCurve = Curves.easeOut;
  static const Curve elementAppearCurve = Curves.easeIn;
  static const Curve hoverCurve = Curves.linear;

  /// Helper to create blurred container decoration for light theme
  static BoxDecoration blurredContainerLight({double opacity = 0.9}) {
    return BoxDecoration(
      color: KoleoColors.lightSurface.withOpacity(opacity),
      borderRadius: BorderRadius.circular(12),
    );
  }

  /// Helper to create blurred container decoration for dark theme
  static BoxDecoration blurredContainerDark({double opacity = 0.9}) {
    return BoxDecoration(
      color: KoleoColors.darkSurface.withOpacity(opacity),
      borderRadius: BorderRadius.circular(12),
    );
  }

  /// Creates an ImageFilter for blur effect
  static ImageFilter blurFilter(double sigma) {
    return ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
  }

  /// Светлая тема
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: KoleoTypography.fontFamily,
        scaffoldBackgroundColor: KoleoColors.lightBackground,
        colorScheme: const ColorScheme.light(
          primary: KoleoColors.lightAccent,
          secondary: KoleoColors.lightAccent,
          surface: KoleoColors.lightSurface,
          error: KoleoColors.danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: KoleoColors.lightSurfaceTransparent,
          foregroundColor: KoleoColors.lightText,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: KoleoTypography.title,
        ),
        textTheme: TextTheme(
          headlineLarge: KoleoTypography.headline.copyWith(
            color: KoleoColors.lightText,
          ),
          titleLarge: KoleoTypography.title.copyWith(
            color: KoleoColors.lightText,
          ),
          bodyLarge: KoleoTypography.body.copyWith(
            color: KoleoColors.lightText,
          ),
          bodyMedium: KoleoTypography.body.copyWith(
            color: KoleoColors.lightTextSecondary,
          ),
          labelSmall: KoleoTypography.caption.copyWith(
            color: KoleoColors.lightTextSecondary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: KoleoColors.lightSurfaceTransparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: KoleoColors.lightAccent,
            foregroundColor: Colors.white,
            textStyle: KoleoTypography.button,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: KoleoColors.lightText,
          size: 20,
        ),
      );

  /// Тёмная тема
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: KoleoTypography.fontFamily,
        scaffoldBackgroundColor: KoleoColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: KoleoColors.darkAccent,
          secondary: KoleoColors.darkAccent,
          surface: KoleoColors.darkSurface,
          error: KoleoColors.danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: KoleoColors.darkSurfaceTransparent,
          foregroundColor: KoleoColors.darkText,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: KoleoTypography.title,
        ),
        textTheme: TextTheme(
          headlineLarge: KoleoTypography.headline.copyWith(
            color: KoleoColors.darkText,
          ),
          titleLarge: KoleoTypography.title.copyWith(
            color: KoleoColors.darkText,
          ),
          bodyLarge: KoleoTypography.body.copyWith(
            color: KoleoColors.darkText,
          ),
          bodyMedium: KoleoTypography.body.copyWith(
            color: KoleoColors.darkTextSecondary,
          ),
          labelSmall: KoleoTypography.caption.copyWith(
            color: KoleoColors.darkTextSecondary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: KoleoColors.darkSurfaceTransparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: KoleoColors.darkAccent,
            foregroundColor: Colors.white,
            textStyle: KoleoTypography.button,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: KoleoColors.darkText,
          size: 20,
        ),
      );
}
