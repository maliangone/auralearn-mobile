import 'package:equatable/equatable.dart';

/// An imported study document (Phase C "document import").
///
/// Pure domain object mirroring the authoritative Drift `documents` row (no
/// Drift / file-picker / PDF concerns). The extracted [content] is stored
/// verbatim so it can be stuffed into the `/solve` model context
/// (context-stuffing, NOT RAG — there is no vector store).
///
/// NOTE on naming: the Drift row exposes the extracted text via the Dart
/// getter `content` (the SQL column itself is named `text`). This entity keeps
/// the same `content` name to avoid the `Table.text()` collision and to read
/// naturally in the feature layer.
class Document extends Equatable {
  /// Stable id (uuid string).
  final String id;

  /// Human-readable title (file name / first line / user label).
  final String title;

  /// Origin of the document: [DocumentSourceType.pdf], `.image`, or `.text`.
  final String sourceType;

  /// Full extracted text, ready to be stuffed into model context. May be empty
  /// for image documents (those are asked via the photo/solve flow instead).
  final String content;

  /// Character count of [content], denormalized for the size-cap UI / gate.
  final int charCount;

  /// Number of pages for paged sources (PDFs). `null` for images / notes.
  final int? pageCount;

  /// Import timestamp.
  final DateTime createdAt;

  /// Last-update timestamp.
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.content,
    required this.charCount,
    this.pageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True when this document has no extractable text to stuff into context
  /// (e.g. an image document, or an empty/failed extraction).
  bool get hasText => content.trim().isNotEmpty;

  /// True when this is an image document (asked via the photo flow, not text).
  bool get isImage => sourceType == DocumentSourceType.image;

  Document copyWith({
    String? id,
    String? title,
    String? sourceType,
    String? content,
    int? charCount,
    int? pageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceType: sourceType ?? this.sourceType,
      content: content ?? this.content,
      charCount: charCount ?? this.charCount,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        sourceType,
        content,
        charCount,
        pageCount,
        createdAt,
        updatedAt,
      ];
}

/// Stable string constants for [Document.sourceType]. Stored as TEXT so new
/// kinds can be added without a schema migration.
abstract final class DocumentSourceType {
  static const String pdf = 'pdf';
  static const String text = 'text';
  static const String image = 'image';
}
