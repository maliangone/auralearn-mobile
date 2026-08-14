import 'package:equatable/equatable.dart';

class HistoryItem extends Equatable {
  final String id;
  final String? question;
  final String? answer;
  final String? explanation;
  final String? subject;
  final String? category;
  final List<String>? imageUrls;
  final double? confidence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  /// Phase-B free-text tags for archive organisation (may be empty, never null).
  final List<String> tags;

  const HistoryItem({
    required this.id,
    this.question,
    this.answer,
    this.explanation,
    this.subject,
    this.category,
    this.imageUrls,
    this.confidence,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.tags = const [],
  });

  HistoryItem copyWith({
    String? id,
    String? question,
    String? answer,
    String? explanation,
    String? subject,
    String? category,
    List<String>? imageUrls,
    double? confidence,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
    );
  }

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
        updatedAt,
        metadata,
        tags,
      ];
} 