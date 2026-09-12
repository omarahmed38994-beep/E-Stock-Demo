import 'package:flutter/material.dart';

/// StockVision brand palette.
/// Primary: deep indigo/navy (enterprise, trustworthy)
/// Accent: teal (data/analytics, "smart")
/// Semantic colors used consistently for severities/status across the app.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1E3A5F); // deep navy
  static const Color primaryLight = Color(0xFF2E5580);
  static const Color accent = Color(0xFF14B8A6); // teal
  static const Color accentDark = Color(0xFF0D9488);

  // Semantic
  static const Color critical = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color success = Color(0xFF22C55E);

  // Neutral - Light theme
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E9F0);
  static const Color lightTextPrimary = Color(0xFF1A2233);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Neutral - Dark theme
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A2129);
  static const Color darkBorder = Color(0xFF2A333F);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Chart palette (distinct, accessible)
  static const List<Color> chartSeries = [
    Color(0xFF14B8A6),
    Color(0xFF1E3A5F),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFFE53E3E),
    Color(0xFF8B5CF6),
    Color(0xFF22C55E),
  ];

  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return critical;
      case 'warning':
        return warning;
      default:
        return info;
    }
  }
}
