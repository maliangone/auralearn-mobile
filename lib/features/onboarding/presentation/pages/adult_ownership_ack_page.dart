import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../l10n/app_localizations.dart';

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
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacyPolicy;
  }

  @override
  void dispose() {
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

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
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.all(AppRadius.rHero),
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
                l.adultAckTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.base),

              // Explanatory body
              Text(
                l.adultAckBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),

              const Spacer(),

              // Acknowledgment checkbox card — whole card toggles; the
              // Checkbox keeps the default (≥44px) Material tap target.
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      const BorderRadius.all(AppRadius.rCard),
                  border: Border.all(
                    color: _acknowledged
                        ? AppColors.primary
                        : AppColors.border,
                    width: _acknowledged ? 1.5 : 1.0,
                  ),
                ),
                child: InkWell(
                  borderRadius: const BorderRadius.all(AppRadius.rCard),
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
                          onChanged: (value) => setState(
                            () => _acknowledged = value ?? false,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: _buildAcknowledgmentText(theme, l),
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
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: Text(
                    l.adultAckStart,
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

  Widget _buildAcknowledgmentText(ThemeData theme, AppLocalizations l) {
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
          TextSpan(text: '${l.adultAckCheckbox} '),
          TextSpan(
            text: l.adultAckPrivacy,
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      await launchUrl(
        Uri.parse(AdultOwnershipAckPage.privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).commonErrorTitle),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
