import 'package:flutter/material.dart';

/// Design tokens exactly matched from the web app's styles.css:
/// Primary: hsl(239 84% 67%) -> #6366F1 / #4F46E5
/// Secondary: hsl(160 84% 39%) -> #059669 / #10B981
/// Background: hsl(210 40% 98%) -> #F8FAFC (Light), hsl(222 47% 6%) -> #080C14 (Dark)
/// Foreground: hsl(222 47% 11%) -> #0F172A (Light), hsl(210 20% 98%) -> #F8FAFC (Dark)
/// Card: #FFFFFF (Light), hsl(217 33% 12%) -> #141C2B (Dark)
/// Border: #E2E8F0 (Light), #222D3E (Dark)
/// Destructive: #EF4444
class AppColors {
  AppColors._();

  // Brand Palette
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color primaryMuted = Color(0x266366F1); // 15% opacity

  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color secondaryLight = Color(0xFFECFDF5);
  static const Color secondaryMuted = Color(0x2610B981);

  // Status Colors
  static const Color destructive = Color(0xFFEF4444); // Red
  static const Color destructiveMuted = Color(0x26EF4444);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningMuted = Color(0x26F59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color successMuted = Color(0x2610B981);

  // Light Theme
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color foregroundLight = Color(0xFF0F172A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color mutedLight = Color(0xFFF1F5F9);
  static const Color mutedForegroundLight = Color(0xFF64748B);
  static const Color inputLight = Color(0xFFE2E8F0);

  // Dark Theme
  static const Color backgroundDark = Color(0xFF080C14);
  static const Color foregroundDark = Color(0xFFF8FAFC);
  static const Color cardDark = Color(0xFF141C2B);
  static const Color borderDark = Color(0xFF222D3E);
  static const Color mutedDark = Color(0xFF192233);
  static const Color mutedForegroundDark = Color(0xFF94A3B8);
  static const Color inputDark = Color(0xFF222D3E);
}
