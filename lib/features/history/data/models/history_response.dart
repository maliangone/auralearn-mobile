import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/history_item.dart';

part 'history_response.g.dart';

@JsonSerializable()
class HistoryResponse {
  final List<HistoryItemModel> items;
  final int totalCount;
  final int page;
  final int limit;
  final bool hasNext;

  const HistoryResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.limit,
    required this.hasNext,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$HistoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryResponseToJson(this);
}

@JsonSerializable()
class HistoryItemModel extends HistoryItem {
  const HistoryItemModel({
    required super.id,
    super.question,
    super.answer,
    super.explanation,
    super.subject,
    super.category,
    super.imageUrls,
    super.confidence,
    required super.createdAt,
    required super.updatedAt,
    super.metadata,
    super.tags = const [],
  });

  factory HistoryItemModel.fromJson(Map<String, dynamic> json) =>
      _$HistoryItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryItemModelToJson(this);

  factory HistoryItemModel.fromEntity(HistoryItem entity) {
    return HistoryItemModel(
      id: entity.id,
      question: entity.question,
      answer: entity.answer,
      explanation: entity.explanation,
      subject: entity.subject,
      category: entity.category,
      imageUrls: entity.imageUrls,
      confidence: entity.confidence,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      metadata: entity.metadata,
      tags: entity.tags,
    );
  }

  HistoryItem toEntity() {
    return HistoryItem(
      id: id,
      question: question,
      answer: answer,
      explanation: explanation,
      subject: subject,
      category: category,
      imageUrls: imageUrls,
      confidence: confidence,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
      tags: tags,
    );
  }
} 