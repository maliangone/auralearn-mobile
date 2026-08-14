import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../core/utils/time_ago.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/history_item.dart';
import 'history_tag_dialog.dart';

/// Card widget for a single [HistoryItem] in the archive list.
///
/// Shows: subject chip (if present) + question preview + time + tags row.
/// A label icon opens the [showTagEditDialog]; delete icon fires [onDelete].
class HistoryItemCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(List<String> tags) onTagsChanged;
  final bool isDeleting;

  const HistoryItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onTagsChanged,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final subjectColor = AppColors.subjectFg(item.subject ?? '');

    return AnimatedOpacity(
      opacity: isDeleting ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDeleting ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: icon + question text + delete button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.question_answer_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.question?.isNotEmpty == true
                                ? item.question!
                                : l.historyNoQuestionText,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              // Subject chip
                              if (item.subject != null) ...[
                                _SubjectChip(
                                  label: item.subject!,
                                  color: subjectColor,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              // Timestamp
                              Text(
                                formatTimeAgo(context, item.createdAt),
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Delete button — ≥44px touch target.
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: l.historyDeleteItem,
                        icon: isDeleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textHint,
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: AppColors.textHint,
                              ),
                        onPressed: isDeleting ? null : onDelete,
                        splashRadius: 22,
                      ),
                    ),
                  ],
                ),
                // Tags row (only shown when tags exist or to show the edit button)
                const SizedBox(height: AppSpacing.xs),
                _TagsRow(
                  tags: item.tags,
                  onEditTap: () async {
                    final result = await showTagEditDialog(
                      context,
                      initialTags: item.tags,
                    );
                    if (result != null) {
                      onTagsChanged(result);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SubjectChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SubjectChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  final List<String> tags;
  final VoidCallback onEditTap;

  const _TagsRow({required this.tags, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Row(
      children: [
        // Edit tag icon — always visible so user can discover tagging.
        // The transparent InkWell padding widens the hit area without
        // inflating the visual pill.
        Tooltip(
          message: l.historyEditTags,
          child: InkWell(
            onTap: onEditTap,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.label_outline_rounded,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    if (tags.isEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l.historyTags,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tags.map((tag) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: _InlineTag(label: tag),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineTag extends StatelessWidget {
  final String label;

  const _InlineTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
