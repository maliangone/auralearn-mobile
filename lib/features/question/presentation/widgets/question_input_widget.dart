import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Bottom input bar for typing a question: attach button + text field +
/// send button that lights up as soon as text is entered.
///
/// Stateful so the send button's enabled/colour state tracks the controller
/// live (the old stateless version read `controller.text` at build time and
/// the button stayed dead until an unrelated rebuild).
class QuestionInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSubmit;
  final VoidCallback onAttachImage;
  final bool isLoading;

  const QuestionInputWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onAttachImage,
    this.isLoading = false,
  });

  @override
  State<QuestionInputWidget> createState() => _QuestionInputWidgetState();
}

class _QuestionInputWidgetState extends State<QuestionInputWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canSend = !widget.isLoading && _hasText;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          // Attach image button
          IconButton(
            onPressed: widget.isLoading ? null : widget.onAttachImage,
            tooltip: l.cameraTitle,
            icon: Icon(
              Icons.add_a_photo_outlined,
              color: widget.isLoading
                  ? AppColors.textHint
                  : AppColors.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Text input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.hero),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      enabled: !widget.isLoading,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l.questionInputHint,
                        hintStyle:
                            const TextStyle(color: AppColors.textHint),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                      onSubmitted:
                          widget.isLoading ? null : widget.onSubmit,
                    ),
                  ),

                  // Send button
                  Container(
                    margin: const EdgeInsets.only(right: AppSpacing.xs),
                    child: IconButton(
                      onPressed: canSend
                          ? () => widget.onSubmit(widget.controller.text)
                          : null,
                      icon: widget.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: _hasText
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                      style: IconButton.styleFrom(
                        backgroundColor: _hasText
                            ? AppColors.primaryLight
                            : Colors.transparent,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
