import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class QuestionInputWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Attach image button
          IconButton(
            onPressed: isLoading ? null : onAttachImage,
            icon: Icon(
              Icons.add_a_photo_outlined,
              color: isLoading ? AppTheme.textHint : AppTheme.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppTheme.border),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Text input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !isLoading,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type your question here...',
                        hintStyle: TextStyle(color: AppTheme.textHint),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                      onSubmitted: isLoading ? null : onSubmit,
                    ),
                  ),

                  // Send button
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: IconButton(
                      onPressed: isLoading || controller.text.trim().isEmpty
                          ? null
                          : () => onSubmit(controller.text),
                      icon: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: controller.text.trim().isEmpty
                                  ? AppTheme.textHint
                                  : AppTheme.primary,
                            ),
                      style: IconButton.styleFrom(
                        backgroundColor: controller.text.trim().isEmpty
                            ? Colors.transparent
                            : AppTheme.primary.withOpacity(0.1),
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