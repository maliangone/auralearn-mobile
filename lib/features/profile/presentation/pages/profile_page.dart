import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/i18n/locale_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Shows a bottom-sheet picker to switch the app language (跟随系统 / 中文 /
/// English), persisted via [LocaleCubit].
Future<void> showLanguagePicker(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final cubit = context.read<LocaleCubit>();
  final current = cubit.state?.languageCode;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) {
      Widget tile(String label, String? code) => ListTile(
            title: Text(label),
            trailing: current == code
                ? const Icon(Icons.check_rounded, color: AppColors.primary)
                : null,
            onTap: () {
              cubit.setLocale(code == null ? null : Locale(code));
              Navigator.of(sheetContext).pop();
            },
          );
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            tile(l.languageSystem, null),
            tile(l.languageChinese, 'zh'),
            tile(l.languageEnglish, 'en'),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).profileTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _AuthenticatedBody(state: state);
          }
          return const _GuestBody();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Guest (not logged in) — friendly empty state with login CTA
// ---------------------------------------------------------------------------
class _GuestBody extends StatelessWidget {
  const _GuestBody();

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
              Icons.account_circle_outlined,
              size: 72,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.profileLoginPrompt,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.profileLoginSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.goNamed('login'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.base),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: Text(
                  l.loginOrRegister,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: () => showLanguagePicker(context),
              icon: const Icon(Icons.language_rounded,
                  size: 18, color: AppColors.textSecondary),
              label: Text(
                l.settingsLanguage,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Authenticated body
// ---------------------------------------------------------------------------
class _AuthenticatedBody extends StatelessWidget {
  final AuthAuthenticated state;

  const _AuthenticatedBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '账号信息',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.base),
                Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        state.user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
                if (state.user.name != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        state.user.name!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Actions card
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.language_rounded,
                  label: AppLocalizations.of(context).settingsLanguage,
                  onTap: () => showLanguagePicker(context),
                ),
                const Divider(height: 1, color: AppColors.border),
                _ActionTile(
                  icon: Icons.settings_outlined,
                  label: '设置',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('设置页面即将上线')),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.border),
                _ActionTile(
                  icon: Icons.help_outline_rounded,
                  label: '帮助与支持',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('帮助页面即将上线')),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.border),
                _ActionTile(
                  icon: Icons.info_outline_rounded,
                  label: '关于',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('关于页面即将上线')),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.border),
                _ActionTile(
                  icon: Icons.logout_rounded,
                  label: '退出登录',
                  labelColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('退出登录'),
                        content: const Text('确定要退出登录吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              context
                                  .read<AuthBloc>()
                                  .add(AuthLogoutRequested());
                              Navigator.of(ctx).pop();
                            },
                            child: const Text(
                              '退出',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action tile
// ---------------------------------------------------------------------------
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          size: 20, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: labelColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
