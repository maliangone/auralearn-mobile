import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';

class UsageIndicator extends StatelessWidget {
  const UsageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        final user = authState.user;
        final usagePercentage = user.usagePercentage;
        final isNearLimit = user.isNearLimit;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isNearLimit 
                ? LinearGradient(
                    colors: [AppTheme.warning.withOpacity(0.1), AppTheme.error.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNearLimit ? AppTheme.warning : AppTheme.border,
              width: isNearLimit ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: isNearLimit ? AppTheme.warning : AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Usage',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${user.usageCount} / ${user.monthlyLimit} questions',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getPlanColor(user.subscriptionPlan).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getPlanColor(user.subscriptionPlan),
                      ),
                    ),
                    child: Text(
                      _getPlanDisplayName(user.subscriptionPlan),
                      style: TextStyle(
                        color: _getPlanColor(user.subscriptionPlan),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(usagePercentage * 100).toInt()}% used',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isNearLimit)
                        Text(
                          'Almost full!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: usagePercentage,
                    backgroundColor: AppTheme.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isNearLimit ? AppTheme.warning : AppTheme.primary,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),

              if (isNearLimit) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: AppTheme.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.subscriptionPlan == 'free' 
                              ? 'Upgrade to continue asking questions'
                              : 'Consider upgrading for more questions',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (user.subscriptionPlan == 'free') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to subscription page
                      // context.go('/subscription');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                    ),
                    child: const Text('Upgrade Plan'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getPlanColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'free':
        return AppTheme.textSecondary;
      case 'standard':
        return AppTheme.primary;
      case 'pro':
        return AppTheme.accent;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getPlanDisplayName(String plan) {
    switch (plan.toLowerCase()) {
      case 'free':
        return 'FREE';
      case 'standard':
        return 'STANDARD';
      case 'pro':
        return 'PRO';
      default:
        return plan.toUpperCase();
    }
  }
} 