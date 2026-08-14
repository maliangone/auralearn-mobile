import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Monthly-usage card shown on the home screen for signed-in users.
/// Near-limit states escalate colour from indigo → amber.
class UsageIndicator extends StatelessWidget {
  const UsageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        final user = authState.user;
        final usagePercentage = user.usagePercentage;
        final isNearLimit = user.isNearLimit;
        final accent = isNearLimit ? AppColors.warning : AppColors.primary;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isNearLimit ? AppColors.warning : AppColors.border,
              width: isNearLimit ? 1.5 : 1,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.analytics_outlined, color: accent, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.usageTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          l.usageQuestions(user.usageCount, user.monthlyLimit),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: _planColor(user.subscriptionPlan)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                    ),
                    child: Text(
                      _planName(l, user.subscriptionPlan),
                      style: TextStyle(
                        color: _planColor(user.subscriptionPlan),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.base),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.usagePercentUsed((usagePercentage * 100).toInt()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isNearLimit)
                    Text(
                      l.usageAlmostFull,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warningDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: usagePercentage,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                minHeight: 8,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),

              if (isNearLimit) ...[
                const SizedBox(height: AppSpacing.base),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warningDark,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          user.subscriptionPlan == 'free'
                              ? l.usageUpgradeHintFree
                              : l.usageUpgradeHintPaid,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warningDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (user.subscriptionPlan == 'free') ...[
                const SizedBox(height: AppSpacing.base),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.goNamed('subscription'),
                    child: Text(l.usageUpgradeButton),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _planColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'standard':
        return AppColors.primary;
      case 'pro':
        return AppColors.warningDark;
      case 'free':
      default:
        return AppColors.textSecondary;
    }
  }

  String _planName(AppLocalizations l, String plan) {
    switch (plan.toLowerCase()) {
      case 'standard':
        return l.planStandard;
      case 'pro':
        return l.planPro;
      case 'free':
      default:
        return l.planFree;
    }
  }
}
