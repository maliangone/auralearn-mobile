import 'package:flutter_bloc/flutter_bloc.dart';

import 'question_event.dart';
import 'question_state.dart';
import '../../domain/usecases/submit_question_usecase.dart';
import '../../../../core/utils/logger.dart';

class QuestionBloc extends Bloc<QuestionEvent, QuestionState> {
  final SubmitQuestionUseCase submitQuestionUseCase;

  QuestionBloc({
    required this.submitQuestionUseCase,
  }) : super(QuestionInitial()) {
    on<QuestionSubmitRequested>(_onQuestionSubmitRequested);
    on<QuestionLoadHistoryRequested>(_onQuestionLoadHistoryRequested);
    on<QuestionDeleteRequested>(_onQuestionDeleteRequested);
  }

  Future<void> _onQuestionSubmitRequested(
    QuestionSubmitRequested event,
    Emitter<QuestionState> emit,
  ) async {
    emit(QuestionSubmitInProgress());

    final result = await submitQuestionUseCase.call(
      SubmitQuestionParams(
        content: event.content,
        images: event.images,
      ),
    );

    result.fold(
      (failure) {
        AppLogger.error('Failed to submit question: ${failure.message}');
        emit(QuestionSubmitFailure(message: failure.message));
      },
      (response) {
        AppLogger.info('Question submitted successfully: ${response.id}');
        emit(QuestionSubmitSuccess(response: response));
      },
    );
  }

  Future<void> _onQuestionLoadHistoryRequested(
    QuestionLoadHistoryRequested event,
    Emitter<QuestionState> emit,
  ) async {
    // TODO: Implement history loading
    AppLogger.info('Question history loading requested');
  }

  Future<void> _onQuestionDeleteRequested(
    QuestionDeleteRequested event,
    Emitter<QuestionState> emit,
  ) async {
    // TODO: Implement question deletion
    AppLogger.info('Question deletion requested: ${event.questionId}');
  }
} 