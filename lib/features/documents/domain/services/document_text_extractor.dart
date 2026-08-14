import 'dart:convert';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../entities/document.dart';

/// Result of extracting text from a picked file. Pure data — the import use
/// case turns this into a persisted [Document].
class ExtractedDocument {
  /// One of [DocumentSourceType.pdf] / `.text` / `.image`.
  final String sourceType;

  /// Extracted text (verbatim, ready for context-stuffing). Empty for images.
  final String content;

  /// Page count for paged sources (PDF); `null` otherwise.
  final int? pageCount;

  const ExtractedDocument({
    required this.sourceType,
    required this.content,
    this.pageCount,
  });

  int get charCount => content.length;
}

/// Thrown when a picked file cannot be parsed (corrupt / locked / unsupported).
/// Carries a user-facing Chinese [message] for the UI.
class DocumentExtractionException implements Exception {
  final String message;
  const DocumentExtractionException(this.message);

  @override
  String toString() => 'DocumentExtractionException: $message';
}

/// Pure, file-picker-free text extraction for imported study documents.
///
/// Kept independent of `file_picker` so the PDF / text / image branches are
/// unit-testable from raw bytes. The import use case owns the file picking and
/// delegates the byte→text work here.
///
/// Branches:
///   - PDF   -> syncfusion `PdfTextExtractor(...).extractText()`; pageCount set.
///   - .txt  -> decoded as UTF-8 (malformed bytes allowed/replaced).
///   - image -> placeholder note; NOT OCR'd here (asked via the photo flow).
class DocumentTextExtractor {
  const DocumentTextExtractor();

  /// Note stored as the body of an image document, explaining that image
  /// sources are answered through the camera/solve flow rather than text
  /// context-stuffing.
  static const String imagePlaceholder =
      '（图片资料）此资料为图片，无法提取文字。请通过拍照解题流程对图片提问。';

  /// File extensions accepted by the picker, lowercase, no leading dot.
  static const List<String> allowedExtensions = [
    'pdf',
    'txt',
    'jpg',
    'jpeg',
    'png',
  ];

  /// Extract text from [bytes] given the lowercase file [extension]
  /// (no leading dot). Throws [DocumentExtractionException] on a corrupt /
  /// unsupported file.
  ExtractedDocument extract({
    required Uint8List bytes,
    required String extension,
  }) {
    final ext = extension.toLowerCase().replaceFirst('.', '');
    switch (ext) {
      case 'pdf':
        return _extractPdf(bytes);
      case 'txt':
        return _extractText(bytes);
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const ExtractedDocument(
          sourceType: DocumentSourceType.image,
          content: imagePlaceholder,
          pageCount: null,
        );
      default:
        throw DocumentExtractionException('不支持的文件类型：.$ext');
    }
  }

  ExtractedDocument _extractPdf(Uint8List bytes) {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      final text = PdfTextExtractor(document).extractText();
      return ExtractedDocument(
        sourceType: DocumentSourceType.pdf,
        content: text.trim(),
        pageCount: pageCount,
      );
    } catch (_) {
      throw const DocumentExtractionException(
        '无法读取该 PDF，文件可能已损坏或被加密。',
      );
    } finally {
      document?.dispose();
    }
  }

  ExtractedDocument _extractText(Uint8List bytes) {
    try {
      // allowMalformed so a stray byte does not abort the whole import.
      final text = utf8.decode(bytes, allowMalformed: true);
      return ExtractedDocument(
        sourceType: DocumentSourceType.text,
        content: text.trim(),
        pageCount: null,
      );
    } catch (_) {
      throw const DocumentExtractionException('无法读取该文本文件。');
    }
  }
}
