import 'package:flutter/material.dart';

const primaryBlue = Color(0xFF0F66E8);
const trustGreen = Color(0xFF11A36A);
const warningAmber = Color(0xFFD99012);
const softBlue = Color(0xFFEAF2FF);
const softGreen = Color(0xFFE7F8EF);
const surface = Color(0xFFF5F8FC);
const cardSurface = Colors.white;
const ink = Color(0xFF11223A);
const mutedInk = Color(0xFF5F6F85);
const border = Color(0xFFD5DFED);

class AppSpace {
  static const double x1 = 8;
  static const double x2 = 16;
  static const double x3 = 24;
}

class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
}

class AppShadow {
  static const light = [
    BoxShadow(
      color: Color(0x12092A59),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  static const medium = [
    BoxShadow(
      color: Color(0x18082E63),
      blurRadius: 18,
      offset: Offset(0, 10),
    ),
  ];

  static const high = [
    BoxShadow(
      color: Color(0x1F083269),
      blurRadius: 24,
      offset: Offset(0, 14),
    ),
  ];
}

ThemeData buildAppTheme(BuildContext context) {
  final base = Theme.of(context).textTheme;

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: trustGreen,
      surface: cardSurface,
    ),
    scaffoldBackgroundColor: surface,
    textTheme: base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        color: ink,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        color: mutedInk,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        color: mutedInk,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF9FBFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      side: BorderSide.none,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      selectedColor: softBlue,
      backgroundColor: const Color(0xFFEDF3FB),
      secondarySelectedColor: softGreen,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardSurface,
      indicatorColor: softBlue,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color:
              states.contains(WidgetState.selected) ? primaryBlue : mutedInk,
        ),
      ),
    ),
  );
}
