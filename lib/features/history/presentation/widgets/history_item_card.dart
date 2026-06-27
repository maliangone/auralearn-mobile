import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.dart';
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    }
  }

  Color _subjectColor(String? subject) {
    if (subject == null) return AppColors.subjectDefault;
    final lower = subject.toLowerCase();
    if (lower.contains('数学') || lower.contains('math')) {
      return AppColors.subjectMath;
    }
    if (lower.contains('物理') || lower.contains('physics')) {
      return AppColors.subjectPhysics;
    }
    if (lower.contains('化学') || lower.contains('chem')) {
      return AppColors.subjectChemistry;
    }
    if (lower.contains('生物') || lower.contains('bio')) {
      return AppColors.subjectBiology;
    }
    return AppColors.subjectDefault;
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = _subjectColor(item.subject);

    return AnimatedOpacity(
      opacity: isDeleting ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDeleting ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
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
                                : '（无题目文字）',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
                                _formatDate(item.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Delete button
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
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
                                size: 18,
                                color: AppColors.textHint,
                              ),
                        onPressed: isDeleting ? null : onDelete,
                        splashRadius: 16,
                      ),
                    ),
                  ],
                ),
                // Tags row (only shown when tags exist or to show the edit button)
                const SizedBox(height: AppSpacing.sm),
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
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
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
    return Row(
      children: [
        // Edit tag icon — always visible so user can discover tagging.
        GestureDetector(
          onTap: onEditTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
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
                  const SizedBox(width: 3),
                  const Text(
                    '标签',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
