import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/di/injection_container.dart';

/// Phase C — Required age-gate / parent-teacher ownership acknowledgment.
///
/// AuraLearn targets K-12 students, but the account is created and managed by
/// an adult (parent or teacher, 18+). This step is MANDATORY: it is shown
/// before onboarding can complete and cannot be bypassed by skipping the
/// carousel slides.
class AdultOwnershipAckPage extends StatefulWidget {
  const AdultOwnershipAckPage({super.key});

  /// Privacy policy URL.
  static const String privacyPolicyUrl = 'https://auralearn.app/privacy';

  /// LocalStorage key for the adult ownership acknowledgment flag.
  ///
  /// NOTE (integration): mirror this in [LocalStorage] as
  /// `static const String keyAdultOwnershipAck = 'adult_ownership_ack';`
  /// alongside the other key constants. Defined here to stay inside the
  /// onboarding lane; the string value is the source of truth.
  static const String keyAdultOwnershipAck = 'adult_ownership_ack';

  @override
  State<AdultOwnershipAckPage> createState() => _AdultOwnershipAckPageState();
}

class _AdultOwnershipAckPageState extends State<AdultOwnershipAckPage> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Shield / guardian icon
              Center(
                child: Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                '家长 / 老师确认',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.base),

              // Explanatory body
              Text(
                '本应用面向 K-12 学生，账号由家长或老师（已满 18 岁）创建并管理。',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),

              const Spacer(),

              // Acknowledgment checkbox card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: _acknowledged
                        ? AppColors.primary
                        : AppColors.border,
                    width: _acknowledged ? 1.5 : 1.0,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => setState(() => _acknowledged = !_acknowledged),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acknowledged,
                          activeColor: AppColors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (value) => setState(
                            () => _acknowledged = value ?? false,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: _buildAcknowledgmentText(theme),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Complete button — disabled until acknowledged
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _acknowledged ? _completeOnboarding : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textHint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    '开始使用',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _acknowledged
                          ? AppColors.textOnPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcknowledgmentText(ThemeData theme) {
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textPrimary,
      height: 1.5,
    );
    final linkStyle = baseStyle?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(
            text: '我已年满 18 岁，作为家长/老师创建并管理此账号，并同意',
          ),
          TextSpan(
            text: '《隐私政策》',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = _openPrivacyPolicy,
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    // TODO(integration): url_launcher is not a dependency. When it is added,
    // launch AdultOwnershipAckPage.privacyPolicyUrl here. For now, surface the
    // URL so the action is visible and non-blocking.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('隐私政策：${AdultOwnershipAckPage.privacyPolicyUrl}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _completeOnboarding() async {
    final localStorage = getIt<LocalStorage>();
    await localStorage.setBool(LocalStorage.keyOnboardingCompleted, true);
    await localStorage.setBool(
      AdultOwnershipAckPage.keyAdultOwnershipAck,
      true,
    );

    if (mounted) {
      context.go('/login');
    }
  }
}
