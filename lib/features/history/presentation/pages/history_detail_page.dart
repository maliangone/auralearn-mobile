import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../l10n/app_localizations.dart';

/// Placeholder for the history detail view.
///
/// The full feature (question + step-by-step answer + images) is not built
/// yet; this shows a clean, styled "coming soon" state instead of a stub.
class HistoryDetailPage extends StatelessWidget {
  final String historyId;

  const HistoryDetailPage({
    super.key,
    required this.historyId,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l.historyDetailTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: AppEmptyState(
        illustration: 'assets/illustrations/empty_history.svg',
        title: l.historyDetailPlaceholderTitle,
        subtitle: l.historyDetailPlaceholderSubtitle,
        inline: true,
      ),
    );
  }
}
