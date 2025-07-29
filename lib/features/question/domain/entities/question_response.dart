import 'package:equatable/equatable.dart';

class QuestionResponse extends Equatable {
  final String id;
  final String? question;
  final String? answer;
  final String? explanation;
  final String? subject;
  final String? category;
  final List<String>? imageUrls;
  final double? confidence;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const QuestionResponse({
    required this.id,
    this.question,
    this.answer,
    this.explanation,
    this.subject,
    this.category,
    this.imageUrls,
    this.confidence,
    required this.createdAt,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        question,
        answer,
        explanation,
        subject,
        category,
        imageUrls,
        confidence,
        createdAt,
        metadata,
      ];
} 