import 'package:flutter/material.dart';

class AppTheme {
  // ==================== ORIGINAL DARK THEME COLORS (KEPT) ====================
  static const Color background = Color(0xFF0B1220);  // Dark background
  static const Color cardDark = Color(0xFF111827);    // Dark cards
  static const Color gold = Color(0xFFD4A24C);        // Gold accent
  static const Color goldLight = Color(0xFFE6B566);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white54;
  
  // ==================== NEW ADDITIONS FOR VICTORIAN STYLE ====================
  static const Color primaryDeepBlue = Color(0xFF1A3A6F);  // Deep blue for buttons
  static const Color secondaryTeal = Color(0xFF0D9488);    // Teal for accents
  static const Color surface = Color(0xFF1E293B);          // Card surface (lighter than background)
  
  // Semantic colors
  static const Color success = Color(0xFF10B981);  // Green
  static const Color warning = Color(0xFFF59E0B);  // Amber
  static const Color error = Color(0xFFEF4444);    // Red
  static const Color info = Color(0xFF3B82F6);     // Blue
  
  // Status badge colors (light backgrounds for dark theme)
  static const Color pendingBadgeBg = Color(0xFFFEF3C7);
  static const Color pendingBadgeText = Color(0xFF92400E);
  static const Color paidBadgeBg = Color(0xFFD1FAE5);
  static const Color paidBadgeText = Color(0xFF065F46);
  
  // Card border
  static const Color cardBorder = Color(0xFF2D3748);
  static const Color textLight = Color(0xFF94A3B8);
  
  // ==================== THEME DATA ====================
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',
    primaryColor: gold,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: secondaryTeal,
      error: error,
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: const BorderSide(color: cardBorder),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    // Card theme - single definition
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
    ),
  );
}