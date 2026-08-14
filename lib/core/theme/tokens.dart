import 'package:flutter/material.dart';

/// Design tokens for AuraLearn.
///
/// v2 — "Warm & friendly" direction: the Linear/Notion restraint stays, but
/// with softer radii, colour-tinted clay shadows and a pastel subject system.
/// Light-first; K-12 audience (child + parent trust).
abstract final class AppColors {
  // --- Primary accent (indigo-blue) ---
  static const Color primary = Color(0xFF4F6EF7);
  static const Color primaryLight = Color(0xFFEEF1FE);
  static const Color primaryDark = Color(0xFF3A54D4);
  static const Color primaryViolet = Color(0xFF7C3AED);

  // --- Encourage / success (warm green) ---
  static const Color encourage = Color(0xFF22C55E);
  static const Color encourageLight = Color(0xFFDCFCE7);
  static const Color encourageDark = Color(0xFF15803D);

  // --- Warning / caution ---
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);

  // --- Error ---
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFB91C1C);

  // --- Neutrals (surfaces & text) ---
  /// Page background — near-white with a faint cool tint
  static const Color background = Color(0xFFF8F9FC);

  /// Card / elevated surface
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle dividers and card borders
  static const Color border = Color(0xFFE8EAF0);

  /// Hover / pressed tint
  static const Color surfaceHover = Color(0xFFF1F3F9);

  // --- Text ---
  static const Color textPrimary = Color(0xFF0F1117);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0B7C3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Subject palette (saturated foreground) ---
  static const Color subjectMath = Color(0xFF2563EB);
  static const Color subjectPhysics = Color(0xFF7C3AED);
  static const Color subjectChemistry = Color(0xFF059669);
  static const Color subjectBiology = Color(0xFFDC2626);
  static const Color subjectEnglish = Color(0xFFEA580C);
  static const Color subjectChinese = Color(0xFFDB2777);
  static const Color subjectHistory = Color(0xFF7C2D12);
  static const Color subjectGeography = Color(0xFF0891B2);
  static const Color subjectDefault = Color(0xFF4F6EF7);

  /// Foreground colour for a subject name (accepts English and Chinese
  /// labels; unknown → [subjectDefault]).
  static Color subjectFg(String subject) {
    switch (subject.trim().toLowerCase()) {
      case 'mathematics':
      case 'math':
      case 'algebra':
      case 'geometry':
      case 'calculus':
      case '数学':
        return subjectMath;
      case 'physics':
      case '物理':
        return subjectPhysics;
      case 'chemistry':
      case '化学':
        return subjectChemistry;
      case 'biology':
      case '生物':
        return subjectBiology;
      case 'english':
      case 'literature':
      case '英语':
        return subjectEnglish;
      case 'chinese':
      case '语文':
        return subjectChinese;
      case 'history':
      case '历史':
        return subjectHistory;
      case 'geography':
      case '地理':
        return subjectGeography;
      case 'computer science':
      case 'programming':
      case '计算机':
        return const Color(0xFF4338CA);
      default:
        return subjectDefault;
    }
  }

  /// Soft pastel background paired with [subjectFg] (≈10% tint).
  static Color subjectBg(String subject) =>
      subjectFg(subject).withValues(alpha: 0.10);
}

abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

abstract final class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;

  /// Standard cards & tiles — friendlier than v1's 12–16.
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const Radius rSm = Radius.circular(sm);
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);
  static const Radius rXl = Radius.circular(xl);
  static const Radius rXxl = Radius.circular(xxl);

  // --- Semantic radii (v2) ---
  /// Cards, tiles, empty-state containers.
  static const double card = 18.0;

  /// Buttons, inputs.
  static const double button = 14.0;

  /// Hero elements (primary CTA).
  static const double hero = 24.0;

  /// Chips, small tags.
  static const double chip = 10.0;

  static const Radius rCard = Radius.circular(card);
  static const Radius rButton = Radius.circular(button);
  static const Radius rHero = Radius.circular(hero);
  static const Radius rChip = Radius.circular(chip);
}

abstract final class AppElevation {
  /// No shadow — flush to surface
  static const double none = 0.0;

  /// Subtle card lift
  static const double low = 1.0;

  /// Standard card / bottom sheet
  static const double medium = 4.0;

  /// Floating elements
  static const double high = 8.0;
}

abstract final class AppShadows {
  /// Soft neutral card shadow — replaces a hard 1px border where lift is
  /// wanted without heaviness.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0xFF0F1117).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0F1117).withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Legacy alias of [soft] — kept so existing references keep compiling.
  static List<BoxShadow> get card => soft;

  /// Colour-tinted clay shadow for tinted/colourful surfaces.
  /// Pass the surface's own accent colour; returns a soft coloured drop.
  static List<BoxShadow> clay(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.22),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: tint.withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// Button press / hero element shadow (primary-tinted).
  static List<BoxShadow> get hero => clay(AppColors.primary);
}

/// Motion tokens — micro-interactions stay in the 100–300ms band.
abstract final class AppMotion {
  static const Duration pressIn = Duration(milliseconds: 110);
  static const Duration pressOut = Duration(milliseconds: 180);
  static const Duration fadeIn = Duration(milliseconds: 250);
  static const Duration staggered = Duration(milliseconds: 320);

  /// Press scale for tappable cards/buttons.
  static const double pressScale = 0.965;
}
