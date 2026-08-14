import 'package:flutter/material.dart';
import 'dart:io';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';

enum _OAuthProvider { google, apple }

class OAuthButton extends StatelessWidget {
  /// Google brand red — used only for the fallback glyph when the Google
  /// logo asset is unavailable. Not a theme token (third-party brand color).
  static const Color _googleBrandRed = Color(0xFFDB4437);

  final VoidCallback onPressed;
  final Widget icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final _OAuthProvider _provider;

  const OAuthButton._({
    required this.onPressed,
    required this.icon,
    required _OAuthProvider provider,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : _provider = provider;

  factory OAuthButton.google({
    required VoidCallback onPressed,
  }) {
    return OAuthButton._(
      onPressed: onPressed,
      provider: _OAuthProvider.google,
      icon: Image.asset(
        'assets/icons/google.png',
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.g_mobiledata,
          size: 22,
          color: OAuthButton._googleBrandRed,
        ),
      ),
      backgroundColor: AppColors.surface,
      textColor: AppColors.textPrimary,
      borderColor: AppColors.border,
    );
  }

  factory OAuthButton.apple({
    required VoidCallback onPressed,
  }) {
    // On iOS use Apple's canonical black button; elsewhere use a light,
    // token-styled variant (web flow / "coming soon" note shown by caller).
    final onIOS = Platform.isIOS;
    return OAuthButton._(
      onPressed: onPressed,
      provider: _OAuthProvider.apple,
      icon: Icon(
        Icons.apple,
        size: 22,
        color: onIOS ? AppColors.textOnPrimary : AppColors.textPrimary,
      ),
      backgroundColor: onIOS ? AppColors.textPrimary : AppColors.surface,
      textColor: onIOS ? AppColors.textOnPrimary : AppColors.textPrimary,
      borderColor: onIOS ? AppColors.textPrimary : AppColors.border,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = switch (_provider) {
      _OAuthProvider.google => l.authSignInWithGoogle,
      _OAuthProvider.apple => l.authSignInWithApple,
    };

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1.5,
        ),
        borderRadius: const BorderRadius.all(AppRadius.rButton),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.all(AppRadius.rButton),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: AppSpacing.md),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
