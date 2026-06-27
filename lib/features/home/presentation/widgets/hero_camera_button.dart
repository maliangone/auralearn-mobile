import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/tokens.dart';

/// Full-width hero CTA for the camera-first home screen.
/// Provides a satisfying press scale + haptic on tap.
class HeroCameraButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final String sublabel;

  const HeroCameraButton({
    super.key,
    required this.onTap,
    this.label = '拍照解题',
    this.sublabel = '拍下题目，立刻获得讲解',
  });

  @override
  State<HeroCameraButton> createState() => _HeroCameraButtonState();
}

class _HeroCameraButtonState extends State<HeroCameraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) async {
        HapticFeedback.lightImpact();
        await _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg + 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.hero,
          ),
          child: Row(
            children: [
              // Camera icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: AppSpacing.base),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.sublabel,
                      style: TextStyle(
                        color: Colors.white.withAlpha(190),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withAlpha(160),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
