import 'package:flutter/material.dart';

/// Consistent design system for the Book Club App - Alquimia Literaria.
/// Inspired by the mystical and literary aesthetic of the club's logo.
/// Requirement 12.4 – uniform typography, colors and spacing.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Brand colors - Alquimia Literaria palette
  // ---------------------------------------------------------------------------

  // Primary: Emerald/Turquoise from the logo
  static const Color _alchemyGreen = Color(0xFF2D9B7F); // Main emerald green
  static const Color _alchemyGreenDark = Color(0xFF1A5F4F); // Darker shade
  static const Color _alchemyGreenLight = Color(0xFF4ECDB3); // Lighter shade
  
  // Secondary: Mystical purple/deep tones
  static const Color _mysticalPurple = Color(0xFF4A148C); // Deep mystical purple
  static const Color _darkBackground = Color(0xFF0D1B2A); // Dark cosmic background
  
  // Accent colors
  static const Color _crystalWhite = Color(0xFFF8F9FA); // Crystal/star white
  static const Color _magicGold = Color(0xFFFFD700); // Golden accents for stars/magic

  // ---------------------------------------------------------------------------
  // Spacing constants (8-pt grid)
  // ---------------------------------------------------------------------------

  static const double spacingXs = 8.0;
  static const double spacingSm = 16.0;
  static const double spacingMd = 24.0;
  static const double spacingLg = 32.0;

  // ---------------------------------------------------------------------------
  // Border radius
  // ---------------------------------------------------------------------------

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;

  // ---------------------------------------------------------------------------
  // Light theme - Alquimia Literaria
  // ---------------------------------------------------------------------------

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _alchemyGreen,
      secondary: _mysticalPurple,
      brightness: Brightness.light,
      tertiary: _magicGold,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // AppBar - Mystical header with gradient effect
      appBarTheme: AppBarTheme(
        backgroundColor: _alchemyGreen,
        foregroundColor: _crystalWhite,
        elevation: 0,
        scrolledUnderElevation: 4,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: _crystalWhite,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          fontFamily: 'serif',
        ),
      ),

      // Cards - Elegant with subtle shadow
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: _alchemyGreen.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(
            color: _alchemyGreenLight.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingXs,
          vertical: spacingXs / 2,
        ),
      ),

      // Elevated buttons - Mystical style
      // NOTE: do NOT use Size.fromHeight here — it sets infinite width which
      // crashes when the button is inside a Row/Column without Expanded.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _alchemyGreen,
          foregroundColor: _crystalWhite,
          minimumSize: const Size(88, 48),
          elevation: 4,
          shadowColor: _alchemyGreen.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingSm,
            vertical: spacingXs,
          ),
        ),
      ),

      // Filled buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingSm,
          vertical: spacingXs + 4,
        ),
      ),

      // Floating action button - Magical accent
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _alchemyGreen,
        foregroundColor: _crystalWhite,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: spacingSm,
      ),

      // Typography
      textTheme: _buildTextTheme(colorScheme),
    );
  }

  // ---------------------------------------------------------------------------
  // Dark theme - Cosmic Alquimia (black with emerald accents)
  // ---------------------------------------------------------------------------

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _alchemyGreen,
      secondary: _mysticalPurple,
      brightness: Brightness.dark,
      tertiary: _magicGold,
      surface: _darkBackground,
      onSurface: _crystalWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBackground,

      // AppBar - Dark mystical
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: _alchemyGreenLight,
        elevation: 0,
        scrolledUnderElevation: 4,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: _alchemyGreenLight,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          fontFamily: 'serif',
        ),
      ),

      // Cards - Dark with emerald glow
      cardTheme: CardThemeData(
        color: const Color(0xFF1A2332),
        elevation: 4,
        shadowColor: _alchemyGreen.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(
            color: _alchemyGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingXs,
          vertical: spacingXs / 2,
        ),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _alchemyGreen,
          foregroundColor: _crystalWhite,
          minimumSize: const Size(88, 48),
          elevation: 6,
          shadowColor: _alchemyGreen.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingSm,
            vertical: spacingXs,
          ),
        ),
      ),

      // Filled buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _alchemyGreenDark,
          foregroundColor: _crystalWhite,
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _alchemyGreenLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),

      // Input fields - Dark with emerald focus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A2332),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: _alchemyGreen.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: _alchemyGreenLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingSm,
          vertical: spacingXs + 4,
        ),
        labelStyle: TextStyle(color: _alchemyGreenLight),
        hintStyle: TextStyle(color: _crystalWhite.withValues(alpha: 0.5)),
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _alchemyGreen,
        foregroundColor: _crystalWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: _alchemyGreenDark,
        labelStyle: const TextStyle(color: _crystalWhite),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: _alchemyGreen.withValues(alpha: 0.3),
        thickness: 1,
        space: spacingSm,
      ),

      // Typography
      textTheme: _buildTextTheme(colorScheme),
    );
  }

  // ---------------------------------------------------------------------------
  // Text theme
  // ---------------------------------------------------------------------------

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}
