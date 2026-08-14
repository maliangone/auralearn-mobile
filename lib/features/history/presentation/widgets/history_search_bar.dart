import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../l10n/app_localizations.dart';

/// Debounced search TextField for the history archive.
///
/// Calls [onChanged] ~300 ms after the user stops typing. Accepts an optional
/// external [controller] so the parent can clear or pre-fill the field (when
/// supplied, the parent owns its lifecycle); otherwise an internal controller
/// is created and disposed here.
class HistorySearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  /// Falls back to the localized `historySearchHint` when null.
  final String? hintText;

  /// Optional externally-owned controller (e.g. so the page can clear the
  /// visible query when filters are reset).
  final TextEditingController? controller;

  const HistorySearchBar({
    super.key,
    required this.onChanged,
    this.onClear,
    this.hintText,
    this.controller,
  });

  @override
  State<HistorySearchBar> createState() => _HistorySearchBarState();
}

class _HistorySearchBarState extends State<HistorySearchBar> {
  late TextEditingController _controller;
  bool _ownsController = false;
  Timer? _debounce;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
  }

  void _attachController(TextEditingController? external) {
    _ownsController = external == null;
    _controller = external ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant HistorySearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _controller.removeListener(_onTextChanged);
      if (_ownsController) _controller.dispose();
      _attachController(widget.controller);
    }
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(_controller.text);
    });
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: _hasText ? AppColors.primary : AppColors.border,
          width: _hasText ? 1.5 : 1.0,
        ),
        boxShadow: _hasText ? AppShadows.soft : null,
      ),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        style: textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? l.historySearchHint,
          hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textHint,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  tooltip: l.commonClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  onPressed: _handleClear,
                  splashRadius: 20,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}
