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
      primaryGradient: primaryGradient,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryGradient: secondaryGradient,
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

  // ULTRA PREMIUM LIGHT THEME
  static final light = CustomColors(
    background: const Color(0xFFF4F7F9),
    surface: const Color(0xFFFFFFFF),
    text: const Color(0xFF012A4A),
    textSecondary: const Color(0xFF4682A9),
    primary: const Color(0xFF014871),
    primaryGradient: [const Color(0xFF014871), const Color(0xFFD7EDE2)], // Exact Inspiration
    secondary: const Color(0xFFD7EDE2),
    secondaryGradient: [const Color(0xFFA3C9C7), const Color(0xFFD7EDE2)],
    accent: const Color(0xFF00A8E8),
    error: const Color(0xFFFF3366),
    border: const Color(0xFFE1E8ED),
    card: const Color(0xFFFFFFFF),
    muted: const Color(0xFF8B98A5),
    white: const Color(0xFFFFFFFF),
    glass: const Color(0xFFFFFFFF).withValues(alpha: 0.85),
    warning: const Color(0xFFF59E0B),
    info: const Color(0xFF3B82F6),
    success: const Color(0xFF10B981),
  );

  // ULTRA PREMIUM DARK THEME
  static final dark = CustomColors(
    background: const Color(0xFF000D1A),
    surface: const Color(0xFF001F33),
    text: const Color(0xFFE1EBF5),
    textSecondary: const Color(0xFF8FB3CE),
    primary: const Color(0xFF014871),
    primaryGradient: [const Color(0xFF012A4A), const Color(0xFF014871), const Color(0xFF4E89AE)],
    secondary: const Color(0xFFD7EDE2),
    secondaryGradient: [const Color(0xFFD7EDE2), const Color(0xFFB8D8D8)],
    accent: const Color(0xFF00B4D8),
    error: const Color(0xFFFF4B4B),
    border: const Color(0xFF1A3D5C),
    card: const Color(0xFF00223B),
    muted: const Color(0xFF5C6A7A),
    white: const Color(0xFFFFFFFF),
    glass: const Color(0xFF000D1A).withValues(alpha: 0.75),
    warning: const Color(0xFFFFB020),
    info: const Color(0xFF60A5FA),
    success: const Color(0xFF34D399),
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
      fontFamily: 'Inter', // Assuming Inter or system default, will look extremely clean
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
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          height: 1.1,
          color: colors.text,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          color: colors.text,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: colors.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
          color: colors.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: colors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Smoother borders
          side: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 0.5, // More subtle borders like premium native apps
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.text),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.text,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}
