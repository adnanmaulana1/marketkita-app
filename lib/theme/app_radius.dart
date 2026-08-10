import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double sm = 4; // chip, badge
  static const double md = 8; // card, button
  static const double lg = 12; // bottom sheet, modal
  static const double xl = 16; // card besar
  static const double full = 999; // avatar, pill

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}
