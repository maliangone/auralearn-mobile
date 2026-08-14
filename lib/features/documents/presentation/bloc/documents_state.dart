import 'package:equatable/equatable.dart';

import '../../domain/entities/document.dart';

/// States for the 我的资料 (document import) list.
sealed class DocumentsState extends Equatable {
  const DocumentsState();

  @override
  List<Object?> get props => [];
}

/// Initial / not-yet-loaded.
class DocumentsInitial extends DocumentsState {
  const DocumentsInitial();
}

/// Loading the document list.
class DocumentsLoading extends DocumentsState {
  const DocumentsLoading();
}

/// Loaded with at least one document.
class DocumentsLoaded extends DocumentsState {
  final List<Document> documents;

  /// True while an import is running on top of an already-loaded list (the
  /// list stays visible and an inline progress affordance is shown).
  final bool importing;

  const DocumentsLoaded(this.documents, {this.importing = false});

  DocumentsLoaded copyWith({List<Document>? documents, bool? importing}) {
    return DocumentsLoaded(
      documents ?? this.documents,
      importing: importing ?? this.importing,
    );
  }

  @override
  List<Object?> get props => [documents, importing];
}

/// Loaded but there are no documents yet (empty state).
class DocumentsEmpty extends DocumentsState {
  /// True while the first import is running from the empty state.
  final bool importing;

  const DocumentsEmpty({this.importing = false});

  @override
  List<Object?> get props => [importing];
}

/// A load / import / delete failed. [message] is user-facing Chinese copy.
class DocumentsError extends DocumentsState {
  final String message;
  const DocumentsError(this.message);

  @override
  List<Object?> get props => [message];
}
