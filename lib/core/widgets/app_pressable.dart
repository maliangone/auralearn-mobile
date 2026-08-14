import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Pressable wrapper that gives any child a satisfying "squish" press:
/// quick scale-down, soft release, light haptic on tap.
///
/// Use for custom tappable cards/tiles that aren't Material buttons.
/// Respects nothing but its own child — wire [onTap] for the action.
class AppPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Semantic label for assistive tech when the child is not self-describing.
  final String? semanticLabel;

  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.pressIn,
      reverseDuration: AppMotion.pressOut,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: AppMotion.pressScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details) async {
    HapticFeedback.lightImpact();
    await _controller.reverse();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _controller.forward(),
      onTapUp: widget.onTap == null ? null : _handleTapUp,
      onTapCancel: _controller.reverse,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
    if (widget.semanticLabel != null) {
      child = Semantics(
        label: widget.semanticLabel,
        button: true,
        child: child,
      );
    }
    return child;
  }
}
