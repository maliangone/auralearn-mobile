// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionResponseModel _$QuestionResponseModelFromJson(
        Map<String, dynamic> json) =>
    QuestionResponseModel(
      id: json['id'] as String,
      question: json['question'] as String?,
      answer: json['answer'] as String?,
      explanation: json['explanation'] as String?,
      subject: json['subject'] as String?,
      category: json['category'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$QuestionResponseModelToJson(
        QuestionResponseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question': instance.question,
      'answer': instance.answer,
      'explanation': instance.explanation,
      'subject': instance.subject,
      'category': instance.category,
      'imageUrls': instance.imageUrls,
      'confidence': instance.confidence,
      'createdAt': instance.createdAt.toIso8601String(),
      'metadata': instance.metadata,
    };
