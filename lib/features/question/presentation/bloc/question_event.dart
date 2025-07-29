import 'package:equatable/equatable.dart';

abstract class QuestionEvent extends Equatable {
  const QuestionEvent();

  @override
  List<Object?> get props => [];
}

class QuestionSubmitRequested extends QuestionEvent {
  final String? content;
  final List<Map<String, dynamic>>? images;

  const QuestionSubmitRequested({
    this.content,
    this.images,
  });

  @override
  List<Object?> get props => [content, images];
}

class QuestionLoadHistoryRequested extends QuestionEvent {}

class QuestionDeleteRequested extends QuestionEvent {
  final String questionId;

  const QuestionDeleteRequested({required this.questionId});

  @override
  List<Object?> get props => [questionId];
} 