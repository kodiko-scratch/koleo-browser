import 'package:flutter/material.dart';

/// Цветовая палитра Koleo Browser
class KoleoColors {
  KoleoColors._();

  // Light theme
  static const lightBackground = Color(0xFFF5F5F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceTransparent = Color(0xE6FFFFFF); // 90% opacity
  static const lightSurfaceTransparent85 = Color(0xD9FFFFFF); // 85% opacity
  static const lightSurfaceTransparent95 = Color(0xF2FFFFFF); // 95% opacity
  static const lightText = Color(0xFF2C2C2C);
  static const lightTextSecondary = Color(0xFF6B6B6B);
  static const lightAccent = Color(0xFF5C7C8A);

  // Dark theme
  static const darkBackground = Color(0xFF1A1A1A);
  static const darkSurface = Color(0xFF2C2C2C);
  static const darkSurfaceTransparent = Color(0xE62C2C2C); // 90% opacity
  static const darkSurfaceTransparent85 = Color(0xD92C2C2C); // 85% opacity
  static const darkSurfaceTransparent95 = Color(0xF22C2C2C); // 95% opacity
  static const darkText = Color(0xFFE8E8E8);
  static const darkTextSecondary = Color(0xFF9A9A9A);
  static const darkAccent = Color(0xFF7BA3B5);

  // Semantic colors
  static const warning = Color(0xFFD4A574);
  static const danger = Color(0xFFC47474);
  static const success = Color(0xFF74C474);

  // Overlay colors
  static const overlayLight = Color(0x80000000); // 50% black overlay
  static const overlayDark = Color(0x80000000); // 50% black overlay
}
