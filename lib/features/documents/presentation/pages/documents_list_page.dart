import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document.dart';
import '../bloc/documents_bloc.dart';
import '../bloc/documents_event.dart';
import '../bloc/documents_state.dart';

/// 我的资料 — list of imported study documents (PDF / text / image). Tapping a
/// document opens the "ask this material" chat (context-stuffing Q&A).
class DocumentsListPage extends StatefulWidget {
  const DocumentsListPage({super.key});

  @override
  State<DocumentsListPage> createState() => _DocumentsListPageState();
}

class _DocumentsListPageState extends State<DocumentsListPage> {
  @override
  void initState() {
    super.initState();
    context.read<DocumentsBloc>().add(const LoadDocuments());
  }

  void _import() => context.read<DocumentsBloc>().add(const ImportDocument());

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
          l.docsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        actions: [
          IconButton(
            tooltip: l.docsImport,
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: _import,
          ),
        ],
      ),
      body: BlocConsumer<DocumentsBloc, DocumentsState>(
        listener: (context, state) {
          if (state is DocumentsError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final bool importing =
              (state is DocumentsLoaded && state.importing) ||
                  (state is DocumentsEmpty && state.importing);

          if (state is DocumentsLoading || state is DocumentsInitial) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            );
          }
          if (state is DocumentsEmpty) {
            return _EmptyState(importing: importing, onImport: _import);
          }
          if (state is DocumentsLoaded) {
            return Column(
              children: [
                if (importing)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.primary,
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    itemCount: state.documents.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => _DocumentCard(
                      document: state.documents[i],
                      onTap: () => context.push(
                        '/documents/ask',
                        extra: state.documents[i],
                      ),
                      onDelete: () => context
                          .read<DocumentsBloc>()
                          .add(DeleteDocument(state.documents[i].id)),
                    ),
                  ),
                ),
              ],
            );
          }
          if (state is DocumentsError) {
            return _ErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<DocumentsBloc>().add(const LoadDocuments()),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool importing;
  final VoidCallback onImport;
  const _EmptyState({required this.importing, required this.onImport});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppEmptyState(
      illustration: 'assets/illustrations/empty_documents.svg',
      title: l.docsEmpty,
      subtitle: importing ? l.docsImporting : l.docsImportSubtitle,
      ctaLabel: importing ? l.docsImporting : l.docsImport,
      // Hide the CTA while an import is running (AppEmptyState only shows it
      // when both label and callback are present).
      onCta: importing ? null : onImport,
      inline: true,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.commonErrorWithMessage(message),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l.commonRetry),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  Future<void> _confirmAndDelete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(l.commonDelete),
        content: Text(l.docsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_iconFor(document.sourceType),
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(l, document),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l.docsDeleteItem,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textHint),
                onPressed: () => _confirmAndDelete(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case DocumentSourceType.pdf:
        return Icons.picture_as_pdf_outlined;
      case DocumentSourceType.image:
        return Icons.image_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  static String _subtitle(AppLocalizations l, Document d) {
    final kind = switch (d.sourceType) {
      DocumentSourceType.pdf => 'PDF',
      DocumentSourceType.image => l.docsTypeImage,
      _ => l.docsTypeText,
    };
    final parts = <String>[kind];
    if (d.pageCount != null) parts.add(l.docsPages(d.pageCount!));
    if (d.charCount > 0) parts.add(l.docsChars(d.charCount));
    return parts.join(' · ');
  }
}
