import 'package:flutter/material.dart';

/// Design tokens for AuraLearn.
/// Light-first, Linear/Notion restraint — clear, trustworthy, with a touch of encouragement.
abstract final class AppColors {
  // --- Primary accent (indigo-blue) ---
  static const Color primary = Color(0xFF4F6EF7);
  static const Color primaryLight = Color(0xFFEEF1FE);
  static const Color primaryDark = Color(0xFF3A54D4);

  // --- Encourage / success (warm green) ---
  static const Color encourage = Color(0xFF22C55E);
  static const Color encourageLight = Color(0xFFDCFCE7);

  // --- Warning / caution ---
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  // --- Error ---
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

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

  // --- Subject chip palette ---
  static const Color subjectMath = Color(0xFF2563EB);
  static const Color subjectPhysics = Color(0xFF7C3AED);
  static const Color subjectChemistry = Color(0xFF059669);
  static const Color subjectBiology = Color(0xFFDC2626);
  static const Color subjectDefault = Color(0xFF4F6EF7);
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
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const Radius rSm = Radius.circular(sm);
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);
  static const Radius rXl = Radius.circular(xl);
  static const Radius rXxl = Radius.circular(xxl);
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
  /// Very subtle card shadow — 1dp equivalent
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF0F1117).withAlpha(10),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF0F1117).withAlpha(6),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Button press / hero element shadow
  static List<BoxShadow> get hero => [
        BoxShadow(
          color: AppColors.primary.withAlpha(50),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
      ];
}
