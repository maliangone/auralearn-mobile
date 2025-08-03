import 'package:flutter/material.dart';
import 'dart:io';

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
      text: 'Continue with Google',
      icon: Image.asset(
        'assets/icons/google.png',
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.g_mobiledata,
          size: 20,
          color: Colors.red,
        ),
      ),
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      borderColor: Colors.grey.shade300,
    );
  }

  factory OAuthButton.apple({
    required VoidCallback onPressed,
  }) {
    return OAuthButton(
      onPressed: onPressed,
      text: 'Continue with Apple',
      icon: Icon(
        Icons.apple,
        size: 20,
        color: Platform.isIOS ? Colors.white : Colors.black,
      ),
      backgroundColor: Platform.isIOS ? Colors.black : Colors.white,
      textColor: Platform.isIOS ? Colors.white : Colors.black,
      borderColor: Platform.isIOS ? Colors.black : Colors.grey.shade300,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        border: Border.all(
          color: borderColor ?? Colors.grey.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.black87,
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
