import 'package:flutter/material.dart';

class AppColors {
  // Golds
  static const gold = Color(0xFFC8A76A);
  static const goldSoft = Color(0xFFD9C39C);

  // Lights
  static const ivory = Color(0xFFFAF7F2);
  static const warmWhite = Color(0xFFF6F1E8);

  // Darks
  static const nearBlack = Color(0xFF0B0B0B);
  static const coal = Color(0xFF111214);
  static const graphite = Color(0xFF1A1B1E);

  // Text
  static const textDark = Color(0xFF1C1C1C);
  static const textMuted = Color(0xFF6E6E6E);
  static const textLight = Color(0xFFEDEBE7);

  // Cards
  static const cardLight = Color(0xFFF9F5EE);
  static const cardDark = Color(0xFF171719);

  // States
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFF3A93B);
  static const danger = Color(0xFFEF5350);

  static Color goldWith(double o) => gold.withOpacity(o);
}

