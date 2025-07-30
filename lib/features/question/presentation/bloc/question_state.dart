import 'package:equatable/equatable.dart';
import '../../domain/entities/question_response.dart';

abstract class QuestionState extends Equatable {
  const QuestionState();

  @override
  List<Object?> get props => [];
}

class QuestionInitial extends QuestionState {}

class QuestionSubmitInProgress extends QuestionState {}

class QuestionSubmitSuccess extends QuestionState {
  final QuestionResponse response;

  const QuestionSubmitSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

class QuestionSubmitFailure extends QuestionState {
  final String message;

  const QuestionSubmitFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class QuestionHistoryLoaded extends QuestionState {
  final List<QuestionResponse> questions;

  const QuestionHistoryLoaded({required this.questions});

  @override
  List<Object?> get props => [questions];
}

class QuestionHistoryError extends QuestionState {
  final String message;

  const QuestionHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
} 