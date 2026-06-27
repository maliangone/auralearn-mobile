import 'package:flutter/material.dart';
import 'dart:io';

import '../../../../core/theme/tokens.dart';

class OAuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Widget icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const OAuthButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  factory OAuthButton.google({
    required VoidCallback onPressed,
  }) {
    return OAuthButton(
      onPressed: onPressed,
      text: '使用 Google 登录',
      icon: Image.asset(
        'assets/icons/google.png',
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.g_mobiledata,
          size: 22,
          color: Color(0xFFDB4437),
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
    return OAuthButton(
      onPressed: onPressed,
      text: '使用 Apple 登录',
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
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1.5,
        ),
        borderRadius: const BorderRadius.all(AppRadius.rMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.all(AppRadius.rMd),
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
