import 'package:flutter/material.dart';

class AppColors {
  // ========================================
  // 🎨 BASE COLOR PALETTE
  // Pure color definitions (no light/dark naming)
  // ========================================

  // Blacks & Grays
  static const Color black = Color(0xFF0D0D0D);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2D2D2D);
  static const Color mediumGray = Color(0xFF757575);
  static const Color lightGray = Color(0xFFBDBDBD);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color paleGray = Color(0xFFF5F5F5);
  
  // Whites
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  
  // Accent Colors

  static const Color blue = Color(0xFF0668AD);
  static const Color blueLight = Color(0xFFE1F2FE);
  static const Color blueDark = Color(0xFF043E68);


  static const Color red = Color(0xFFFF3B30);
  static const Color redLight = Color(0xFFFF6B66);
  static const Color redDark = Color(0xFFE63026);
  
  // Semantic Colors
  static const Color green = Color(0xFF00D4AA);
  static const Color yellow = Color(0xFFFFC107);

  // ========================================
  // LIGHT COLOR SCHEME
  // ========================================
  static ColorScheme get lightScheme => const ColorScheme(
        brightness: Brightness.light,
        
        // Primary (Blue Accent)
        primary: blue,
        onPrimary: white,
        primaryContainer: blueLight,
        onPrimaryContainer: black,
        
        // Secondary (Neutral)
        secondary: charcoal,
        onSecondary: white,
        secondaryContainer: paleGray,
        onSecondaryContainer: black,
        
        // Tertiary (Green)
        tertiary: green,
        onTertiary: white,
        tertiaryContainer: Color(0xFFCCFFF0),
        onTertiaryContainer: Color(0xFF00332A),
        
        // Error
        error: red,
        onError: white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        
        // Surface & Background
        surface: white,
        onSurface: black,
        onSurfaceVariant: mediumGray,
        
        // Surface containers
        surfaceContainerHighest: paleGray,
        surfaceContainer: offWhite,
        surfaceContainerHigh: offWhite,
        surfaceContainerLow: white,
        surfaceContainerLowest: white,
        
        // Outline
        outline: borderGray,
        outlineVariant: Color(0xFFF0F0F0),
        
        // Shadow & Scrim
        shadow: black,
        scrim: black,
        
        // Inverse
        inverseSurface: charcoal,
        onInverseSurface: offWhite,
        inversePrimary: blueLight,
      );

  // ========================================
  // 🌙 DARK COLOR SCHEME
  // ========================================
  static ColorScheme get darkScheme => const ColorScheme(
        brightness: Brightness.dark,
        
        // Primary (Blue Accent - same)
        primary: blue,
        onPrimary: black,
        primaryContainer: blueDark,
        onPrimaryContainer: offWhite,
        
        // Secondary (Inverted)
        secondary: offWhite,
        onSecondary: black,
        secondaryContainer: darkGray,
        onSecondaryContainer: offWhite,
        
        // Tertiary (Green)
        tertiary: green,
        onTertiary: black,
        tertiaryContainer: Color(0xFF00664D),
        onTertiaryContainer: Color(0xFFCCFFF0),
        
        // Error
        error: redLight,
        onError: black,
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        
        // Surface & Background (blacks/grays)
        surface: black,
        onSurface: offWhite,
        onSurfaceVariant: lightGray,
        
        // Surface containers
        surfaceContainerHighest: Color(0xFF3D3D3D),
        surfaceContainer: charcoal,
        surfaceContainerHigh: Color(0xFF242424),
        surfaceContainerLow: black,
        surfaceContainerLowest: Color(0xFF000000),
        
        // Outline
        outline: Color(0xFF3D3D3D),
        outlineVariant: Color(0xFF242424),
        
        // Shadow & Scrim
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        
        // Inverse
        inverseSurface: offWhite,
        onInverseSurface: black,
        inversePrimary: blueDark,
      );

  // ========================================
  // 🎨 GRADIENTS
  // ========================================
  static const LinearGradient accentGradient = LinearGradient(
    colors: [blue, blueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerLight = LinearGradient(
    colors: [paleGray, borderGray, paleGray],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient shimmerDark = LinearGradient(
    colors: [darkGray, charcoal, darkGray],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient glassLight = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassDark = LinearGradient(
    colors: [Color(0x1A000000), Color(0x0D000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========================================
  // 🌑 SHADOWS
  // ========================================
  static List<BoxShadow> get shadowLight => [
        BoxShadow(
          color: black.withAlpha(20),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get shadowElevatedLight => [
        BoxShadow(
          color: black.withAlpha(31),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get shadowDark => [
        const BoxShadow(
          color: Color(0xFF000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get shadowElevatedDark => [
        const BoxShadow(
          color: Color(0xFF000000),
          blurRadius: 32,
          offset: Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get accentGlow => [
        BoxShadow(
          color: blue.withAlpha(77),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  // ========================================
  // 🛠️ HELPER METHODS
  // ========================================
  static Color getPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color getSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  static Color getTertiary(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;

  static Color getSurface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color getBackground(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color getError(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  static List<BoxShadow> getCardShadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? shadowLight
          : shadowDark;

  static List<BoxShadow> getElevatedShadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? shadowElevatedLight
          : shadowElevatedDark;

  static LinearGradient getShimmer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? shimmerLight
          : shimmerDark;

  static LinearGradient getGlass(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? glassLight
          : glassDark;
}