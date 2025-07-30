import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/question_response.dart';

part 'question_response.g.dart';

@JsonSerializable()
class QuestionResponseModel extends QuestionResponse {
  const QuestionResponseModel({
    required super.id,
    super.question,
    super.answer,
    super.explanation,
    super.subject,
    super.category,
    super.imageUrls,
    super.confidence,
    required super.createdAt,
    super.metadata,
  });

  factory QuestionResponseModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionResponseModelToJson(this);

  factory QuestionResponseModel.fromEntity(QuestionResponse entity) {
    return QuestionResponseModel(
      id: entity.id,
      question: entity.question,
      answer: entity.answer,
      explanation: entity.explanation,
      subject: entity.subject,
      category: entity.category,
      imageUrls: entity.imageUrls,
      confidence: entity.confidence,
      createdAt: entity.createdAt,
      metadata: entity.metadata,
    );
  }

  QuestionResponse toEntity() {
    return QuestionResponse(
      id: id,
      question: question,
      answer: answer,
      explanation: explanation,
      subject: subject,
      category: category,
      imageUrls: imageUrls,
      confidence: confidence,
      createdAt: createdAt,
      metadata: metadata,
    );
  }
} 