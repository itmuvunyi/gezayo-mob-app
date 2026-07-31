import 'package:flutter/material.dart';

/// Centralized color palette matching the prototype design system.
abstract class AppColors {
  // Brand Primary Green Palette
  static const Color primary = Color(0xFF046A38);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF024724);
  static const Color primaryMint = Color(0xFFD1FAE5);
  static const Color primarySubtle = Color(0xFFECFDF5);

  // Accent & Brand Colors
  static const Color accentOrange = Color(0xFFD97706);
  static const Color accentOrangeLight = Color(0xFFFFF7ED);
  static const Color accentOrangeDark = Color(0xFFB45309);

  // Surface & Neutral Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardBorderDark = Color(0xFF334155);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Category Colors
  static const Color foodBg = Color(0xFFE6F4EA);
  static const Color foodIcon = Color(0xFF046A38);

  static const Color groceryBg = Color(0xFFFFEDD5);
  static const Color groceryIcon = Color(0xFFC2410C);

  static const Color parcelBg = Color(0xFFEEF2FF);
  static const Color parcelIcon = Color(0xFF4338CA);

  static const Color errandsBg = Color(0xFFE0F2FE);
  static const Color errandsIcon = Color(0xFF0369A1);

  // Status Colors
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusSuccessBg = Color(0xFFD1FAE5);

  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusWarningBg = Color(0xFFFEF3C7);

  static const Color statusError = Color(0xFFEF4444);
  static const Color statusErrorBg = Color(0xFFFEE2E2);

  static const Color statusInfo = Color(0xFF3B82F6);
  static const Color statusInfoBg = Color(0xFFDBEAFE);

  // Map & Navigation Overlays
  static const Color mapOverlayBg = Color(0xCC0F172A);
  static const Color radarScan = Color(0x3310B981);
}
