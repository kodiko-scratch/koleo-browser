import 'package:flutter/material.dart';

/// Типографика Koleo Browser
class KoleoTypography {
  KoleoTypography._();

  static const fontFamily = 'Google Sans';

  static const headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}
