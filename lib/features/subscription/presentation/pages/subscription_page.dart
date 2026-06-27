import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/subscription_status.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '会员',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
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
              const SnackBar(
                content: Text('已升级到 Pro 会员'),
                backgroundColor: AppColors.encourage,
              ),
            );
          } else if (state is SubscriptionStoreUnavailable) {
            messenger.showSnackBar(
              const SnackBar(content: Text('当前设备不支持内购')),
            );
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading ||
              state is SubscriptionPurchasing) {
            return _LoadingState(
              label: state is SubscriptionPurchasing ? '正在处理购买…' : null,
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
          return const SizedBox.shrink();
        },
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          children: [
            const _CardHeader(
              icon: Icons.workspace_premium_outlined,
              iconColor: AppColors.textSecondary,
              title: '免费版',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '每天 ${AppConfig.freeDailyQuota} 题',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '升级 Pro 解锁无限提问',
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
            const _CardHeader(
              icon: Icons.workspace_premium,
              iconColor: AppColors.warning,
              title: 'Pro 会员',
            ),
            const SizedBox(height: AppSpacing.md),
            const _FeatureRow(text: '无限提问，不再受每日上限'),
            const SizedBox(height: AppSpacing.sm),
            const _FeatureRow(text: '更快的解题响应'),
            const SizedBox(height: AppSpacing.sm),
            const _FeatureRow(text: '随时在设置中管理订阅'),
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
              '升级 Pro',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
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
              '恢复购买',
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
    final expiry = status.expiresAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          highlight: true,
          children: [
            const _CardHeader(
              icon: Icons.workspace_premium,
              iconColor: AppColors.warning,
              title: 'Pro 会员',
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
                Text(
                  '已开通，畅享无限提问',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (expiry != null) ...[
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                label: '有效期至',
                value:
                    '${expiry.year}/${_two(expiry.month)}/${_two(expiry.day)}',
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
            label: const Text('恢复购买'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.border,
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: AppShadows.card,
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
              '暂时无法获取订阅信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message.isNotEmpty ? message : '请检查网络后重试',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
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
// Info row helper
// ---------------------------------------------------------------------------
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
