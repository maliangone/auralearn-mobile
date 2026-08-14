import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../l10n/app_localizations.dart';

/// Modal dialog for adding/removing tags on a history item.
///
/// Returns the final `List<String>` of tags when the user taps confirm, or
/// `null` if they dismiss/cancel. The dialog is self-contained — no BLoC
/// reference — so the caller decides what to dispatch.
Future<List<String>?> showTagEditDialog(
  BuildContext context, {
  required List<String> initialTags,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => _TagEditDialog(initialTags: initialTags),
  );
}

class _TagEditDialog extends StatefulWidget {
  final List<String> initialTags;

  const _TagEditDialog({required this.initialTags});

  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  late final List<String> _tags;
  late final TextEditingController _controller;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    _tags = List.of(widget.initialTags);
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    // Support comma-separated batch input.
    final parts = trimmed
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() {
      _inputError = null;
      for (final tag in parts) {
        if (!_tags.contains(tag)) {
          _tags.add(tag);
        }
      }
      _controller.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg,
      ),
      title: Row(
        children: [
          const Icon(Icons.label_outline_rounded,
              size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l.historyEditTags,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing tag chips.
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _tags.map((tag) {
                  return _TagChip(
                    label: tag,
                    onDelete: () => _removeTag(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // Input row.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: _tags.isEmpty,
                    textInputAction: TextInputAction.done,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: l.historyTagsHint,
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textHint,
                      ),
                      errorText: _inputError,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _AddButton(onTap: () => _addTag(_controller.text)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.historyTagsTapToDelete,
              style: textTheme.labelSmall?.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(List.of(_tags)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: Text(l.commonConfirm),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _TagChip({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDelete,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm + 2),
          child: Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}
