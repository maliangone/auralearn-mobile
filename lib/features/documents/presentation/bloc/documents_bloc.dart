import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/delete_document_usecase.dart';
import '../../domain/usecases/get_documents_usecase.dart';
import '../../domain/usecases/import_document_usecase.dart';
import 'documents_event.dart';
import 'documents_state.dart';

/// BLoC for the 我的资料 (document import) list. Loads imported documents,
/// imports a new one via the file picker, and deletes by id. All work goes
/// through the local-first Drift-backed repository (no network).
class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  final GetDocumentsUseCase getDocuments;
  final ImportDocumentUseCase importDocument;
  final DeleteDocumentUseCase deleteDocument;

  DocumentsBloc({
    required this.getDocuments,
    required this.importDocument,
    required this.deleteDocument,
  }) : super(const DocumentsInitial()) {
    on<LoadDocuments>(_onLoad);
    on<ImportDocument>(_onImport);
    on<DeleteDocument>(_onDelete);
  }

  Future<void> _onLoad(LoadDocuments event, Emitter<DocumentsState> emit) async {
    emit(const DocumentsLoading());
    final result = await getDocuments();
    result.fold(
      (f) => emit(DocumentsError(f.message)),
      (docs) => emit(
        docs.isEmpty ? const DocumentsEmpty() : DocumentsLoaded(docs),
      ),
    );
  }

  Future<void> _onImport(
    ImportDocument event,
    Emitter<DocumentsState> emit,
  ) async {
    // Keep the list visible with an inline progress affordance while importing.
    final current = state;
    if (current is DocumentsLoaded) {
      emit(current.copyWith(importing: true));
    } else if (current is DocumentsEmpty) {
      emit(const DocumentsEmpty(importing: true));
    } else {
      emit(const DocumentsLoading());
    }

    final result = await importDocument();
    result.fold(
      (f) => emit(DocumentsError(f.message)), // surfaced via the page listener
      (_) {}, // null == user cancelled; nothing to surface
    );
    // Always reload to refresh the list and clear the importing flag.
    add(const LoadDocuments());
  }

  Future<void> _onDelete(
    DeleteDocument event,
    Emitter<DocumentsState> emit,
  ) async {
    final result = await deleteDocument(DeleteDocumentParams(id: event.id));
    result.fold(
      (f) => emit(DocumentsError(f.message)),
      (_) {},
    );
    add(const LoadDocuments());
  }
}
