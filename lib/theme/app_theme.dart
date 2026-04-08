import 'package:flutter/material.dart';

class CustomColors extends ThemeExtension<CustomColors> {
  final Color background;
  final Color surface;
  final Color text;
  final Color textSecondary;
  final Color primary;
  final List<Color> primaryGradient;
  final Color secondary;
  final List<Color> secondaryGradient;
  final Color accent;
  final Color error;
  final Color border;
  final Color card;
  final Color muted;
  final Color white;
  final Color glass;
  final Color warning;
  final Color info;
  final Color success;

  CustomColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.primary,
    required this.primaryGradient,
    required this.secondary,
    required this.secondaryGradient,
    required this.accent,
    required this.error,
    required this.border,
    required this.card,
    required this.muted,
    required this.white,
    required this.glass,
    required this.warning,
    required this.info,
    required this.success,
  });

  @override
  CustomColors copyWith({
    Color? background,
    Color? surface,
    Color? text,
    Color? textSecondary,
    Color? primary,
    List<Color>? primaryGradient,
    Color? secondary,
    List<Color>? secondaryGradient,
    Color? accent,
    Color? error,
    Color? border,
    Color? card,
    Color? muted,
    Color? white,
    Color? glass,
    Color? warning,
    Color? info,
    Color? success,
  }) {
    return CustomColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondary: secondary ?? this.secondary,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      accent: accent ?? this.accent,
      error: error ?? this.error,
      border: border ?? this.border,
      card: card ?? this.card,
      muted: muted ?? this.muted,
      white: white ?? this.white,
      glass: glass ?? this.glass,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      success: success ?? this.success,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryGradient: primaryGradient, // Simplification
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryGradient: secondaryGradient, // Simplification
      accent: Color.lerp(accent, other.accent, t)!,
      error: Color.lerp(error, other.error, t)!,
      border: Color.lerp(border, other.border, t)!,
      card: Color.lerp(card, other.card, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      white: Color.lerp(white, other.white, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }

  static final light = CustomColors(
    background: const Color(0xFFF8F9FA),
    surface: const Color(0xFFFFFFFF),
    text: const Color(0xFF1A1D1E),
    textSecondary: const Color(0xFF707070),
    primary: const Color(0xFFFF7043),
    primaryGradient: [const Color(0xFFFF8A65), const Color(0xFFFF7043)],
    secondary: const Color(0xFF4FC3F7),
    secondaryGradient: [const Color(0xFF81D4FA), const Color(0xFF4FC3F7)],
    accent: const Color(0xFFFF9E80),
    error: const Color(0xFFE57373),
    border: const Color(0xFFEEEEEE),
    card: const Color(0xFFFFFFFF),
    muted: const Color(0xFFBDBDBD),
    white: const Color(0xFFFFFFFF),
    glass: Colors.white.withValues(alpha: 0.9),
    warning: const Color(0xFFFFB74D),
    info: const Color(0xFF64B5F6),
    success: const Color(0xFF81C784),
  );

  static final dark = CustomColors(
    background: const Color(0xFF121212),
    surface: const Color(0xFF1E1E1E),
    text: const Color(0xFFE0E0E0),
    textSecondary: const Color(0xFFA0A0A0),
    primary: const Color(0xFFFF8A65),
    primaryGradient: [const Color(0xFFFFAB91), const Color(0xFFFF8A65)],
    secondary: const Color(0xFF81D4FA),
    secondaryGradient: [const Color(0xFFB3E5FC), const Color(0xFF81D4FA)],
    accent: const Color(0xFFFFCCBC),
    error: const Color(0xFFEF9A9A),
    border: const Color(0xFF2C2C2C),
    card: const Color(0xFF1E1E1E),
    muted: const Color(0xFF616161),
    white: const Color(0xFFFFFFFF),
    glass: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
    warning: const Color(0xFFFFE082),
    info: const Color(0xFF90CAF9),
    success: const Color(0xFFA5D6A7),
  );
}

class AppTheme {
  static ThemeData getTheme(bool isDarkMode) {
    final colors = isDarkMode ? CustomColors.dark : CustomColors.light;
    
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      colorScheme: ColorScheme(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: Colors.white,
        secondary: colors.secondary,
        onSecondary: Colors.white,
        error: colors.error,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.text,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          color: colors.text,
        ),
        displayMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: colors.text,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: colors.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: colors.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: colors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
      ),
    );
  }
}
