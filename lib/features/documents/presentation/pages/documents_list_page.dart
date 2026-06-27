import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/entities/document.dart';
import '../bloc/documents_bloc.dart';
import '../bloc/documents_event.dart';
import '../bloc/documents_state.dart';

/// 我的资料 — list of imported study documents (PDF / 文本 / 图片). Tapping a
/// document opens the "向这份资料提问" chat (context-stuffing Q&A).
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的资料'),
        actions: [
          IconButton(
            tooltip: '导入资料',
            icon: const Icon(Icons.add_rounded),
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
          final bool importing = (state is DocumentsLoaded && state.importing) ||
              (state is DocumentsEmpty && state.importing);

          if (state is DocumentsLoading || state is DocumentsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DocumentsEmpty) {
            return _EmptyState(importing: importing, onImport: _import);
          }
          if (state is DocumentsLoaded) {
            return Column(
              children: [
                if (importing) const LinearProgressIndicator(minHeight: 2),
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
          // DocumentsError (transient; a reload follows) — show a retry view.
          return _EmptyState(importing: importing, onImport: _import);
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              '还没有导入资料',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '导入课本、讲义或 PDF，向它提问',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: importing ? null : onImport,
              icon: importing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload_file_rounded),
              label: Text(importing ? '导入中…' : '导入资料'),
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
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
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(document),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '删除',
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textHint),
                onPressed: onDelete,
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

  static String _subtitle(Document d) {
    final kind = switch (d.sourceType) {
      DocumentSourceType.pdf => 'PDF',
      DocumentSourceType.image => '图片',
      _ => '文本',
    };
    final parts = <String>[kind];
    if (d.pageCount != null) parts.add('${d.pageCount} 页');
    if (d.charCount > 0) parts.add('${d.charCount} 字');
    return parts.join(' · ');
  }
}
