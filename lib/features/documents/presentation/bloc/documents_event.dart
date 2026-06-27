import 'package:equatable/equatable.dart';

/// Events for the 我的资料 (document import) list.
sealed class DocumentsEvent extends Equatable {
  const DocumentsEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) all imported documents, newest-first.
class LoadDocuments extends DocumentsEvent {
  const LoadDocuments();
}

/// Open the file picker and import the selected PDF / .txt / image.
class ImportDocument extends DocumentsEvent {
  const ImportDocument();
}

/// Delete a single imported document by [id].
class DeleteDocument extends DocumentsEvent {
  final String id;
  const DeleteDocument(this.id);

  @override
  List<Object?> get props => [id];
}
