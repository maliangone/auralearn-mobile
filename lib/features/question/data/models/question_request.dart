import 'package:json_annotation/json_annotation.dart';

part 'question_request.g.dart';

@JsonSerializable()
class QuestionRequest {
  final String? content;
  final List<String>? imageUrls;
  final String? subject;
  final String? category;
  final Map<String, dynamic>? metadata;

  const QuestionRequest({
    this.content,
    this.imageUrls,
    this.subject,
    this.category,
    this.metadata,
  });

  factory QuestionRequest.fromJson(Map<String, dynamic> json) =>
      _$QuestionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionRequestToJson(this);
} 