import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// Standardised empty / placeholder state: brand illustration, title,
/// subtitle and an optional call-to-action.
///
/// Pass [illustration] as an asset path under assets/ (SVG). When null, a
/// neutral fallback icon is shown so the widget never breaks a layout while
/// assets are pending.
class AppEmptyState extends StatelessWidget {
  /// Asset path, e.g. 'assets/illustrations/empty_history.svg'.
  final String? illustration;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  /// Diameter of the illustration box. Defaults to 160.
  final double illustrationSize;

  /// When true the content is centred with no card chrome (for full-page
  /// states); when false it renders inside a soft card (for in-list states).
  final bool inline;

  const AppEmptyState({
    super.key,
    this.illustration,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.illustrationSize = 160,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIllustration(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: theme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: theme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
        if (ctaLabel != null && onCta != null) ...[
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: onCta,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(ctaLabel!),
          ),
        ],
      ],
    );

    if (inline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: content,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.base,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: content,
    );
  }

  Widget _buildIllustration() {
    final path = illustration;
    if (path == null) {
      return const Icon(
        Icons.auto_awesome_rounded,
        size: 48,
        color: AppColors.textHint,
      );
    }
    return SvgPicture.asset(
      path,
      width: illustrationSize,
      height: illustrationSize,
      placeholderBuilder: (_) => SizedBox(
        width: illustrationSize,
        height: illustrationSize,
        child: const Center(
          child: Icon(Icons.auto_awesome_rounded,
              size: 48, color: AppColors.textHint),
        ),
      ),
    );
  }
}
