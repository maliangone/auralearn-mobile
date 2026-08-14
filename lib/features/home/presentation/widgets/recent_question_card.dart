import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Compact card for a recently-solved question (home + history list).
/// Subject chip colours come from the shared token system
/// ([AppColors.subjectFg] / [AppColors.subjectBg]).
class RecentQuestionCard extends StatelessWidget {
  final String question;
  final String subject;
  final String time;
  final bool hasImages;
  final VoidCallback onTap;

  const RecentQuestionCard({
    super.key,
    required this.question,
    required this.subject,
    required this.time,
    required this.hasImages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subjectFg = AppColors.subjectFg(subject);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.subjectBg(subject),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      subject,
                      style: TextStyle(
                        color: subjectFg,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (hasImages) ...[
                    const Icon(
                      Icons.image_rounded,
                      size: 16,
                      color: AppColors.encourage,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                question,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
