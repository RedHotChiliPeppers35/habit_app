import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color backgroundCream = Color(0xFFF3F5F9); // light grey/white

  // Dark surface (bottom bar, overlays)
  static const Color surfaceDark = Color(0xFF111827); // dark navy/charcoal

  // Brand / primary – electric blues
  static const Color primaryBlue = Color(0xFF2563EB); // vivid electric blue
  static const Color primaryBlueSoft = Color(
    0xFFDDE7FF,
  ); // pale blue for chips/cards

  // Accent – orange
  static const Color accentRed = Color(
    0xFFF97316,
  ); // vibrant orange (like Tailwind's orange-500)

  // Borders & dividers
  static const Color borderSoft = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary = Color(0xFF0F172A); // almost-black navy
  static const Color textSecondary = Color(0xFF6B7280); // neutral grey
}

class AppTextStyles {
  // iOS-ish scale
  static const largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );
  static const title1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
  static const title2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
  static const title3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);

  static const headline = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 17, fontWeight: FontWeight.w400);
  static const callout = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static const subhead = TextStyle(fontSize: 15, fontWeight: FontWeight.w500);
  static const footnote = TextStyle(fontSize: 13, fontWeight: FontWeight.w400);
  static const caption2 = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
}
