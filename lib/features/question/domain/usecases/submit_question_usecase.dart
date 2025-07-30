import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/question_response.dart';
import '../repositories/question_repository.dart';

class SubmitQuestionUseCase {
  final QuestionRepository repository;

  SubmitQuestionUseCase(this.repository);

  Future<Either<Failure, QuestionResponse>> call(SubmitQuestionParams params) async {
    return await repository.submitQuestion(params.content, params.images);
  }
}

class SubmitQuestionParams {
  final String? content;
  final List<Map<String, dynamic>>? images;

  SubmitQuestionParams({
    this.content,
    this.images,
  });
} 