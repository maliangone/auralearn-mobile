import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/question_response.dart';

abstract class QuestionRepository {
  Future<Either<Failure, QuestionResponse>> submitQuestion(
    String? content,
    List<Map<String, dynamic>>? images,
  );
  
  Future<Either<Failure, List<QuestionResponse>>> getQuestionHistory();
  
  Future<Either<Failure, void>> deleteQuestion(String questionId);
} 