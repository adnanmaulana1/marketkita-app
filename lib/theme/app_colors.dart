import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand (tetap hitam sebagai primary)
  static const Color primary = Color(0xFF171717);
  static const Color primaryDark = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Aksen
  static const Color accent = Color(0xFFFFB800); // kuning promo/badge
  static const Color onAccent = Color(0xFF171717);
  static const Color danger = Color(0xFFE74C3C);
  static const Color success = Color(0xFF27AE60);

  // Neutral scale
  static const Color neutral900 = Color(0xFF212121);
  static const Color neutral700 = Color(0xFF4E4E4E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);

  // Background halaman (abu super muda, lebih segar dari neutral100)
  static const Color background = Color(0xFFF6F6F7);

  // Elevation konsisten untuk semua kartu: blur 8, opacity 6%, offset (0,2)
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
}
