import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';
import '../services/document_text_extractor.dart';

/// Picks a study file (PDF / .txt / image), extracts its text and persists it
/// as a [Document] for later context-stuffing into `/solve`.
///
/// Flow: `file_picker` (single file) -> [DocumentTextExtractor] (bytes->text)
/// -> [DocumentRepository.save]. Returns the saved [Document] on success.
///
/// Failure mapping:
///   - user cancelled the picker        -> [Right(null)] (no document)
///   - unreadable / corrupt / unsupported (extractor throws
///     [DocumentExtractionException]) -> [Left(ValidationFailure)] with the
///     Chinese message from the extractor.
///   - persistence error               -> the repository's [Failure].
class ImportDocumentUseCase {
  final DocumentRepository repository;
  final DocumentTextExtractor extractor;
  final Uuid _uuid;

  ImportDocumentUseCase({
    required this.repository,
    this.extractor = const DocumentTextExtractor(),
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  /// Opens the picker and imports the selected file. The returned value is
  /// `null` when the user cancelled the picker (not an error).
  Future<Either<Failure, Document?>> call() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: DocumentTextExtractor.allowedExtensions,
        withData: true,
      );
    } catch (e) {
      return Left(ValidationFailure('无法打开文件选择器：$e'));
    }

    if (result == null || result.files.isEmpty) {
      // User cancelled.
      return const Right(null);
    }

    final picked = result.files.single;
    final Uint8List? bytes = picked.bytes;
    if (bytes == null) {
      return const Left(ValidationFailure('无法读取所选文件。'));
    }

    final extension = (picked.extension ?? '').toLowerCase();
    final ExtractedDocument extracted;
    try {
      extracted = extractor.extract(bytes: bytes, extension: extension);
    } on DocumentExtractionException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ValidationFailure('无法读取该文件：$e'));
    }

    final now = DateTime.now();
    final title = _titleFor(picked.name, extracted.content);
    final document = Document(
      id: _uuid.v4(),
      title: title,
      sourceType: extracted.sourceType,
      content: extracted.content,
      charCount: extracted.charCount,
      pageCount: extracted.pageCount,
      createdAt: now,
      updatedAt: now,
    );

    final saveResult = await repository.save(document);
    return saveResult.map((_) => document);
  }

  /// Title = picked file name without extension, falling back to the first
  /// non-empty line of the extracted text, then a generic label.
  String _titleFor(String fileName, String content) {
    final dot = fileName.lastIndexOf('.');
    final base = (dot > 0 ? fileName.substring(0, dot) : fileName).trim();
    if (base.isNotEmpty) return base;

    for (final line in content.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty) return t.length > 40 ? t.substring(0, 40) : t;
    }
    return '未命名资料';
  }
}
