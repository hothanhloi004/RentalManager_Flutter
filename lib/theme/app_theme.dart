import 'package:flutter/material.dart';

/// Màu & style đồng bộ app Android (`res/values/colors.xml`).
class AppTheme {
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color headerTint = Color(0xFFC7D2FE);
  static const Color background = Color(0xFFEFF2F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color onSurface = Color(0xFF1E293B);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFF97316);
  static const Color iconPurpleBg = Color(0xFFEEEDFF);
  static const Color iconRedBg = Color(0xFFFFEBEE);
  static const Color iconOrangeBg = Color(0xFFFFF7E6);
  static const Color iconTealBg = Color(0xFFE0F2F1);
  static const Color iconOrange = Color(0xFFF57C00);
  static const Color iconTeal = Color(0xFF00897B);
  static const Color alertRedBg = Color(0xFFFDF2F4);
  static const Color alertRedText = Color(0xFFD32F2F);
  static const Color alertOrangeBg = Color(0xFFFFF9F4);
  static const Color alertOrangeText = Color(0xFFE65100);
  static const Color divider = Color(0xFFE5E7EB);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primary,
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: surface,
          foregroundColor: onSurface,
          titleTextStyle: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: iconPurpleBg,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}
