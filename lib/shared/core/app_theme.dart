import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bio-Clock Emerald Claymorphism Master Theme
///
/// Deep forest night backgrounds with 3D inflated emerald components.
class AppTheme {
  AppTheme._();

  // ── Master Theme Tokens: Emerald Clay ───────────────────────────

  // Backgrounds
  static const Color bgDeep = Color(0xFF071409);
  static const Color bgMid = Color(0xFF0C1E10);

  // Surfaces
  static const Color surfaceBase = Color(0xFF112616);
  static const Color surfaceUp = Color(0xFF183120);
  static const Color surfacePeak = Color(0xFF1F3D28);
  static const Color surfaceDimDark = Color(0xFF0C1018); // fallback
  static const Color surfaceDimLight = Color(0xFFE8ECF0); // fallback

  // Primaries
  static const Color emeraldCore = Color(0xFF10B981);
  static const Color emeraldBrite = Color(0xFF34D399);
  static const Color emeraldGlow = Color(0xFF6EE7B7);

  // Status/Accents
  static const Color statusExpire = Color(0xFFF97316);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentAmber = Color(0xFFF59E0B);

  // LEGACY ALIASES (to prevent breaking other screens)
  static const Color accentGreen = emeraldCore;
  static const Color accentCyan = emeraldBrite;
  static const Color accentRed = statusExpire;

  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [emeraldCore, emeraldBrite],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientPurpleCyan = LinearGradient(
    colors: [accentPurple, emeraldBrite],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientAmber = LinearGradient(
    colors: [accentAmber, Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const double glassBlurSigma = 10.0;
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceLightLight = Color(0xFFF5F5F5);
  static const Color surfaceLightDark = Color(0xFF333333);
  static const Color surfaceLight = Color(0xFFE0E0E0);

  // Texts
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x66FFFFFF);

  // ── Shadows (Claymorphism) ──────────────────────────────────────

  // 3-layer structural lift
  static List<BoxShadow> get clayShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.6),
          offset: const Offset(0, 8),
          blurRadius: 16,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: bgDeep.withValues(alpha: 0.8),
          offset: const Offset(0, 2),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ];

  // Upward emerald pulse
  static List<BoxShadow> get clayGlowShadow => [
        ...clayShadow,
        BoxShadow(
          color: emeraldGlow.withValues(alpha: 0.25),
          offset: const Offset(0, -4),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> neonGlow(Color color, {double intensity = 0.5}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.25 * intensity),
        blurRadius: 10,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.1 * intensity),
        blurRadius: 20,
        spreadRadius: 4,
      ),
    ];
  }

  // ── Rounded Radius ────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 24; // Aggressive rounding
  static const double radiusXl = 28; // Required by ClayCard
  static const double radiusXxl = 32;
  static const double radiusRound = 100;

  // ── THEME ──────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: emeraldCore,
        onPrimary: Colors.black,
        secondary: emeraldBrite,
        onSecondary: Colors.black,
        tertiary: accentPurple,
        onTertiary: Colors.white,
        surface: surfaceBase,
        onSurface: textPrimary,
        error: statusExpire,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        // Headings - Nunito
        displayLarge: GoogleFonts.nunito(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          height: 1.1,
          letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.nunito(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.2,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),

        // Body - DM Sans
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          color: textSecondary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          color: textMuted,
        ),

        // Data/Labels - Space Mono
        labelSmall: GoogleFonts.spaceMono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: textMuted,
        ),
        labelMedium: GoogleFonts.spaceMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.spaceMono(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surfaceBase,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldCore,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceBase,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: surfacePeak),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: surfaceUp),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: emeraldCore, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textMuted),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: emeraldBrite,
        inactiveTrackColor: surfaceUp,
        thumbColor: emeraldGlow,
        overlayColor: emeraldGlow.withValues(alpha: 0.15),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceUp,
        thickness: 1,
      ),
      extensions: const [
        AppThemeExtension(
          glassBackground: Color(0x14FFFFFF),
          glassBorder: Color(0x18FFFFFF),
          textMuted: textMuted,
          textSecondary: textSecondary,
          surfaceDim: surfaceDimDark,
        ),
      ],
    );
  }

  // ── Light Theme: Paper-Mint ─────────────────────────────────────
  static ThemeData get lightTheme {
    const bgLight = Color(0xFFF0FDF4); // Paper-Mint background
    const surfaceLight = Color(0xFFFFFFFF);
    const textDark = Color(0xFF1A2E1A); // Deep charcoal-green
    const textSecLight = Color(0xFF4A6B4A);
    const textMutedLight = Color(0xFF8CA38C);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: emeraldCore,
        onPrimary: Colors.white,
        secondary: emeraldBrite,
        onSecondary: Colors.white,
        tertiary: accentPurple,
        onTertiary: Colors.white,
        surface: surfaceLight,
        onSurface: textDark,
        error: statusExpire,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.nunito(
          fontSize: 40, fontWeight: FontWeight.w800,
          color: textDark, height: 1.1, letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.nunito(
          fontSize: 28, fontWeight: FontWeight.bold,
          color: textDark, height: 1.2,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 20, fontWeight: FontWeight.w600, color: textDark,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 18, fontWeight: FontWeight.w700, color: textDark,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16, color: textSecLight, height: 1.5,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14, color: textSecLight, height: 1.5,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12, color: textMutedLight,
        ),
        labelSmall: GoogleFonts.spaceMono(
          fontSize: 10, fontWeight: FontWeight.w600,
          letterSpacing: 1.2, color: textMutedLight,
        ),
        labelMedium: GoogleFonts.spaceMono(
          fontSize: 12, fontWeight: FontWeight.w600, color: textSecLight,
        ),
        labelLarge: GoogleFonts.spaceMono(
          fontSize: 14, fontWeight: FontWeight.w700, color: textDark,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textDark,
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldCore,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE8F5E9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: Color(0xFFD0E8D0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: Color(0xFFD0E8D0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: emeraldCore, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textMutedLight),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: emeraldCore,
        inactiveTrackColor: const Color(0xFFD0E8D0),
        thumbColor: emeraldCore,
        overlayColor: emeraldCore.withValues(alpha: 0.15),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFD0E8D0),
        thickness: 1,
      ),
      extensions: const [
        AppThemeExtension(
          glassBackground: Color(0x0A000000), // very subtle dark tint on white
          glassBorder: Color(0x14000000),
          textMuted: textMutedLight,
          textSecondary: textSecLight,
          surfaceDim: surfaceDimLight,
        ),
      ],
    );
  }
}

/// Theme extension to carry custom tokens through [ThemeData].
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color glassBackground;
  final Color glassBorder;
  final Color textMuted;
  final Color textSecondary;
  final Color surfaceDim;

  const AppThemeExtension({
    required this.glassBackground,
    required this.glassBorder,
    required this.textMuted,
    required this.textSecondary,
    required this.surfaceDim,
  });

  @override
  AppThemeExtension copyWith({
    Color? glassBackground,
    Color? glassBorder,
    Color? textMuted,
    Color? textSecondary,
    Color? surfaceDim,
  }) {
    return AppThemeExtension(
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
      textMuted: textMuted ?? this.textMuted,
      textSecondary: textSecondary ?? this.textSecondary,
      surfaceDim: surfaceDim ?? this.surfaceDim,
    );
  }

  @override
  AppThemeExtension lerp(
      covariant ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
    );
  }
}

/// Convenience extensions for [BuildContext].
extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  bool get isDark => theme.brightness == Brightness.dark;
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textStyles => theme.textTheme;
  AppThemeExtension get ext => theme.extension<AppThemeExtension>()!;
  bool get isWide => MediaQuery.sizeOf(this).width >= 600;
}
