import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../repositories/question_repository.dart';
import '../../data/repositories/question_repository_impl.dart';

class UploadImagesUseCase {
  final QuestionRepository repository;

  UploadImagesUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(UploadImagesParams params) async {
    if (repository is QuestionRepositoryImpl) {
      return await (repository as QuestionRepositoryImpl).uploadImages(params.images);
    }
    return const Left(UnknownFailure('Repository does not support image upload'));
  }
}

class UploadImagesParams {
  final List<MultipartFile> images;

  UploadImagesParams({required this.images});
} 