import 'package:flutter/material.dart';

/// Tokens for the parent sign-in screen.
///
/// Colors, radius, spacing, motion, and type all live here so the login
/// page can be retuned in one place. Buttons read these values; they do
/// not invent their own.
class LoginStyle {
  const LoginStyle._();

  // Background and text. Soft off-white, sky blue, readable ink.
  static const Color background = Color(0xFFF7FAFC);
  static const Color accent = Color(0xFF3490DC);
  static const Color accentSoft = Color(0xFFE7F2FB);

  /// Darker sky blue for 14–16px text on [background] and white buttons.
  /// [accent] is the border and brand color; it is too light for body type.
  static const Color accentText = Color(0xFF2B6CB0);
  static const Color success = Color(0xFF48BB78);
  static const Color successSoft = Color(0xFFE5F6ED);
  static const Color warning = Color(0xFFED8936);
  static const Color warningSoft = Color(0xFFFDF0E6);
  static const Color textMain = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  /// Darker orange so short error lines stay readable on [background].
  static const Color warningText = Color(0xFF9C4221);
  static const Color divider = Color(0xFFE2E8F0);

  // Official control colors. Do not recolor the Google or Apple marks.
  static const Color googleFill = Color(0xFFFFFFFF);
  static const Color googleStroke = Color(0xFF747775);
  static const Color googleText = Color(0xFF1F1F1F);
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleGreen = Color(0xFF34A853);
  static const Color appleFill = Color(0xFF000000);
  static const Color appleText = Color(0xFFFFFFFF);
  static const Color guestFill = Color(0xFFFFFFFF);

  // Radius. Shared by every login button.
  static const double radius = 12;
  static const double logoRadius = 28;
  static const double blockRadius = 8;

  // Spacing.
  static const double pageHorizontal = 24;
  static const double pageVertical = 8;
  static const double buttonGap = 12;
  static const double blockGap = 6;
  static const double logoToName = 16;
  static const double nameToHeadline = 28;
  static const double headlineToSubtitle = 8;
  static const double afterActions = 12;

  // Sizes. Button height stays above the 48px tap target.
  static const double buttonHeight = 52;
  static const double minTarget = 48;
  static const double logoBox = 96;
  static const double brandSlot = 24;
  static const double contentMaxWidth = 420;
  static const double borderWidth = 1;

  // Motion. Press is a small scale. The page fades in once.
  static const Duration pressDuration = Duration(milliseconds: 120);
  static const Duration enterDuration = Duration(milliseconds: 280);
  static const double pressScale = 0.98;

  // Type scale.
  static const double titleSize = 28;
  static const double headlineSize = 22;
  static const double subtitleSize = 15;
  static const double buttonSize = 16;
  static const double legalSize = 14;
  static const double errorSize = 14;
  static const double dividerSize = 14;

  /// San Francisco on Apple platforms, Roboto everywhere else.
  static String fontFamily(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return '.SF Pro Text';
      default:
        return 'Roboto';
    }
  }

  static TextStyle title(TargetPlatform platform) {
    return TextStyle(
      fontFamily: fontFamily(platform),
      fontSize: titleSize,
      height: 34 / titleSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: textMain,
    );
  }

  static TextStyle headline(TargetPlatform platform) {
    return TextStyle(
      fontFamily: fontFamily(platform),
      fontSize: headlineSize,
      height: 28 / headlineSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: textMain,
    );
  }

  static TextStyle subtitle(TargetPlatform platform) {
    return TextStyle(
      fontFamily: fontFamily(platform),
      fontSize: subtitleSize,
      height: 22 / subtitleSize,
      fontWeight: FontWeight.w400,
      color: textSecondary,
    );
  }

  static TextStyle button(TargetPlatform platform, Color color) {
    return TextStyle(
      fontFamily: fontFamily(platform),
      fontSize: buttonSize,
      height: 20 / buttonSize,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  static TextStyle legal(TargetPlatform platform) {
    return TextStyle(
      fontFamily: fontFamily(platform),
      fontSize: legalSize,
      height: 20 / legalSize,
      fontWeight: FontWeight.w600,
      color: accentText,
    );
  }

  static TextStyle dividerLabel(TargetPlatform platform) {
    return TextStyle(
      fontFamily: fontFamily(platform),
      fontSize: dividerSize,
      height: 20 / dividerSize,
      fontWeight: FontWeight.w600,
      color: textSecondary,
    );
  }

  static TextStyle error(TargetPlatform platform) {
    return TextStyle(
      fontFamily: fontFamily(platform),
      fontSize: errorSize,
      height: 20 / errorSize,
      fontWeight: FontWeight.w600,
      color: warningText,
    );
  }
}
