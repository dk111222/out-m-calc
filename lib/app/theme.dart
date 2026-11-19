import 'package:flutter/material.dart';

/// Token values live here. Widgets read [AppColors] and [AppSpace].

const motionFast = Duration(milliseconds: 120);
const motionBase = Duration(milliseconds: 180);

class AppSpace {
  static const s0 = 0.0;
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;
  static const rSm = 8.0;
  static const rMd = 12.0;
  static const rLg = 16.0;
  static const rPill = 999.0;
  static const minTarget = 48.0;
  static const header = 56.0;
  static const column = 720.0;
  static const keypadMax = 480.0;
  static const wide = 600.0;
  static const sideBySide = 640.0;
}

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.sunken,
    required this.border,
    required this.borderInput,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.success,
    required this.warning,
    required this.stepA,
    required this.stepB,
    required this.stepC,
    required this.cardShadow,
    required this.popShadow,
  });

  final Color bg;
  final Color surface;
  final Color sunken;
  final Color border;
  final Color borderInput;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color success;
  final Color warning;
  final Color stepA;
  final Color stepB;
  final Color stepC;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> popShadow;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  Color step(int index) {
    switch (index) {
      case 1:
        return stepA;
      case 2:
        return stepB;
      case 3:
        return stepC;
      default:
        return text;
    }
  }

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? sunken,
    Color? border,
    Color? borderInput,
    Color? text,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    Color? danger,
    Color? success,
    Color? warning,
    Color? stepA,
    Color? stepB,
    Color? stepC,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? popShadow,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      sunken: sunken ?? this.sunken,
      border: border ?? this.border,
      borderInput: borderInput ?? this.borderInput,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      stepA: stepA ?? this.stepA,
      stepB: stepB ?? this.stepB,
      stepC: stepC ?? this.stepC,
      cardShadow: cardShadow ?? this.cardShadow,
      popShadow: popShadow ?? this.popShadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      sunken: Color.lerp(sunken, other.sunken, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderInput: Color.lerp(borderInput, other.borderInput, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      stepA: Color.lerp(stepA, other.stepA, t)!,
      stepB: Color.lerp(stepB, other.stepB, t)!,
      stepC: Color.lerp(stepC, other.stepC, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      popShadow: t < 0.5 ? popShadow : other.popShadow,
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  const ink = Color(0xFF1C2330);
  final colors = dark
      ? const AppColors(
          bg: Color(0xFF161A18),
          surface: Color(0xFF222824),
          sunken: Color(0xFF1B201E),
          border: Color(0xFF3C433E),
          borderInput: Color(0xFFC2B8A6),
          text: Color(0xFFF3EFE6),
          textMuted: Color(0xFFC9C1B3),
          accent: Color(0xFF9DCDC2),
          onAccent: Color(0xFF10211C),
          danger: Color(0xFFF0B4AE),
          success: Color(0xFFA9D4BB),
          warning: Color(0xFFE4C48A),
          stepA: Color(0xFFE7B2A8),
          stepB: Color(0xFFA9D0E0),
          stepC: Color(0xFFB7D7B8),
          cardShadow: [],
          popShadow: [],
        )
      : AppColors(
          bg: const Color(0xFFF4F1EA),
          surface: const Color(0xFFFFFFFF),
          sunken: const Color(0xFFEBE6DC),
          border: const Color(0xFFDDD6C8),
          borderInput: const Color(0xFF6B6458),
          text: ink,
          textMuted: const Color(0xFF5C564C),
          accent: const Color(0xFF2F5C55),
          onAccent: const Color(0xFFFFFFFF),
          danger: const Color(0xFF8C3330),
          success: const Color(0xFF1F5C40),
          warning: const Color(0xFF7A4E10),
          stepA: const Color(0xFF8C4038),
          stepB: const Color(0xFF2F5C73),
          stepC: const Color(0xFF2E5A3E),
          cardShadow: [
            BoxShadow(
              color: ink.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
          popShadow: [
            BoxShadow(
              color: ink.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        );
  final scheme = ColorScheme(
    brightness: brightness,
    primary: colors.accent,
    onPrimary: colors.onAccent,
    secondary: colors.accent,
    onSecondary: colors.onAccent,
    error: colors.danger,
    onError: colors.onAccent,
    surface: colors.surface,
    onSurface: colors.text,
    outline: colors.borderInput,
    outlineVariant: colors.border,
  );
  TextStyle style(double size, double line, FontWeight weight, Color color) {
    return TextStyle(
      fontFamily: 'Source Sans 3',
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.bg,
    fontFamily: 'Source Sans 3',
    splashFactory: NoSplash.splashFactory,
    extensions: [colors],
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: AppSpace.header,
      titleTextStyle: style(20, 28, FontWeight.w600, colors.text),
    ),
    textTheme: TextTheme(
      labelSmall: style(12, 16, FontWeight.w600, colors.text),
      bodySmall: style(14, 20, FontWeight.w400, colors.textMuted),
      bodyMedium: style(16, 24, FontWeight.w400, colors.text),
      titleMedium: style(20, 28, FontWeight.w600, colors.text),
      headlineSmall: style(28, 34, FontWeight.w600, colors.text),
      displaySmall: style(40, 48, FontWeight.w600, colors.text),
    ),
    focusColor: colors.borderInput,
  );
}
