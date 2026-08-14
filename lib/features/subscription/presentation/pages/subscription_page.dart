import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/subscription_status.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';

/// TEMP: keys not yet in the ARB files — reported as missing. Delete this
/// extension once the keys land in app_en.arb / app_zh.arb and regenerate.
extension _MissingSubL10n on AppLocalizations {
  /// en: "Upgrade to Pro for unlimited questions"
  /// zh: "升级 Pro 解锁无限提问"
  String get subUpgradeHint =>
      localeName == 'zh' ? '升级 Pro 解锁无限提问' : 'Upgrade to Pro for unlimited questions';
}

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(const LoadStatus());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l.subTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          // Guests can't load billing status — show plan cards + sign-in CTA
          // instead of the error/offline view.
          if (authState is! AuthAuthenticated) {
            return const _GuestView();
          }
          return _buildSubscriptionBody(context, l);
        },
      ),
    );
  }

  Widget _buildSubscriptionBody(BuildContext context, AppLocalizations l) {
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listenWhen: (prev, curr) =>
            curr is SubscriptionPurchaseError ||
            curr is SubscriptionPurchaseSuccess ||
            curr is SubscriptionStoreUnavailable,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is SubscriptionPurchaseError) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is SubscriptionPurchaseSuccess) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(l.subUpgraded),
                backgroundColor: AppColors.encourage,
              ),
            );
          } else if (state is SubscriptionStoreUnavailable) {
            messenger.showSnackBar(
              SnackBar(content: Text(l.subUnavailableStore)),
            );
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading ||
              state is SubscriptionPurchasing) {
            return _LoadingState(
              label: state is SubscriptionPurchasing ? l.subProcessing : null,
            );
          }

          if (state is SubscriptionOfflineError) {
            return _OfflineErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<SubscriptionBloc>().add(const LoadStatus()),
            );
          }

          final status = _statusFrom(state);
          if (status != null) {
            return _StatusView(status: status, priceLabel: _priceFrom(state));
          }

          // SubscriptionInitial / store-unavailable with no cached status.
          return const _SkeletonState();
        },
      );
  }

  SubscriptionStatus? _statusFrom(SubscriptionState state) {
    if (state is SubscriptionLoaded) return state.status;
    if (state is SubscriptionPurchaseSuccess) return state.status;
    if (state is SubscriptionStoreUnavailable) return state.status;
    return null;
  }

  String? _priceFrom(SubscriptionState state) =>
      state is SubscriptionLoaded ? state.priceLabel : null;
}

// ---------------------------------------------------------------------------
// Loaded status view — free vs paid
// ---------------------------------------------------------------------------
class _StatusView extends StatelessWidget {
  final SubscriptionStatus status;
  final String? priceLabel;

  const _StatusView({required this.status, this.priceLabel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status.isPaid)
            _PaidCard(status: status)
          else
            _FreeCard(priceLabel: priceLabel),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Free tier card + upgrade CTA
// ---------------------------------------------------------------------------
class _FreeCard extends StatelessWidget {
  final String? priceLabel;
  const _FreeCard({this.priceLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          children: [
            _CardHeader(
              icon: Icons.workspace_premium_outlined,
              iconColor: AppColors.textSecondary,
              title: l.subFree,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.subDailyQuota(AppConfig.freeDailyQuota),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.subUpgradeHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        // Pro upsell card
        _Card(
          highlight: true,
          children: [
            _CardHeader(
              icon: Icons.workspace_premium,
              iconColor: AppColors.warning,
              title: l.subPro,
            ),
            const SizedBox(height: AppSpacing.md),
            _FeatureRow(text: l.subProFeature1),
            const SizedBox(height: AppSpacing.sm),
            _FeatureRow(text: l.subProFeature2),
            const SizedBox(height: AppSpacing.sm),
            _FeatureRow(text: l.subProFeature3),
            if (priceLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                priceLabel!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () =>
                context.read<SubscriptionBloc>().add(const BuyRequested()),
            icon: const Icon(Icons.upgrade_rounded, size: 20),
            label: Text(
              l.subUpgradeToPro,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: () =>
                context.read<SubscriptionBloc>().add(const RestoreRequested()),
            child: Text(
              l.subRestorePurchase,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Paid (Pro) card
// ---------------------------------------------------------------------------
class _PaidCard extends StatelessWidget {
  final SubscriptionStatus status;
  const _PaidCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final expiry = status.expiresAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          highlight: true,
          children: [
            _CardHeader(
              icon: Icons.workspace_premium,
              iconColor: AppColors.warning,
              title: l.subPro,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.encourage,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l.subProActive,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (expiry != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l.subValidUntil(
                    '${expiry.year}/${_two(expiry.month)}/${_two(expiry.day)}'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                context.read<SubscriptionBloc>().add(const RestoreRequested()),
            icon: const Icon(Icons.restore_rounded, size: 18),
            label: Text(l.subRestorePurchase),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------
class _Card extends StatelessWidget {
  final List<Widget> children;
  final bool highlight;
  const _Card({required this.children, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.border,
          width: highlight ? 1.5 : 1,
        ),
        boxShadow:
            highlight ? AppShadows.clay(AppColors.primary) : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  const _CardHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_rounded, color: AppColors.encourage, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loading state
// ---------------------------------------------------------------------------
class _LoadingState extends StatelessWidget {
  final String? label;
  const _LoadingState({this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.base),
            Text(
              label!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Offline / error state
// ---------------------------------------------------------------------------
class _OfflineErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OfflineErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.subUnavailableTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message.isNotEmpty ? message : l.subUnavailableOffline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l.commonRetry),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Guest view — not signed in: plan cards + sign-in CTA instead of errors
// ---------------------------------------------------------------------------
class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.subGuestTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.subGuestSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Card(
            children: [
              _CardHeader(
                icon: Icons.workspace_premium_outlined,
                iconColor: AppColors.textSecondary,
                title: l.subFree,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l.subDailyQuota(AppConfig.freeDailyQuota),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          _Card(
            highlight: true,
            children: [
              _CardHeader(
                icon: Icons.workspace_premium,
                iconColor: AppColors.warning,
                title: l.subPro,
              ),
              const SizedBox(height: AppSpacing.md),
              _FeatureRow(text: l.subProFeature1),
              const SizedBox(height: AppSpacing.sm),
              _FeatureRow(text: l.subProFeature2),
              const SizedBox(height: AppSpacing.sm),
              _FeatureRow(text: l.subProFeature3),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.goNamed('login'),
              icon: const Icon(Icons.login_rounded, size: 20),
              label: Text(
                l.subGuestCta,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton placeholder — initial / store-unavailable without cached status
// ---------------------------------------------------------------------------
class _SkeletonState extends StatelessWidget {
  const _SkeletonState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: const [
        SkeletonBox(height: 120, radius: AppRadius.card),
        SizedBox(height: AppSpacing.base),
        SkeletonBox(height: 220, radius: AppRadius.card),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 52, radius: AppRadius.button),
      ],
    );
  }
}
