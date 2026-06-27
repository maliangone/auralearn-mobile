import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.dart';

/// Horizontal scrolling row of subject filter chips.
///
/// Always shows a "全部" chip as the first item. Selected chip uses
/// [AppColors.primary] fill; unselected chips use a ghost style.
class HistorySubjectChips extends StatelessWidget {
  final List<String> subjects;
  final String? selectedSubject;
  final ValueChanged<String?> onSubjectSelected;

  const HistorySubjectChips({
    super.key,
    required this.subjects,
    required this.selectedSubject,
    required this.onSubjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) return const SizedBox.shrink();

    final allSubjects = [null, ...subjects]; // null = "全部"

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        itemCount: allSubjects.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final subject = allSubjects[index];
          final isSelected = subject == selectedSubject;
          final label = subject ?? '全部';

          return _SubjectChip(
            label: label,
            isSelected: isSelected,
            onTap: () => onSubjectSelected(subject),
          );
        },
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubjectChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: isSelected
                  ? null
                  : Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
