import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'question_event.dart';
import 'question_state.dart';
import '../../data/datasources/question_local_data_source.dart';
import '../../data/models/question_response.dart';
import '../../domain/usecases/submit_question_usecase.dart';
import '../../../../core/network/streaming/solve_client.dart';
import '../../../../core/network/streaming/solve_event.dart';
import '../../../../core/utils/logger.dart';

/// Bloc driving the streaming `/solve` flow.
///
/// Streaming model: [QuestionSolveRequested] opens a [SolveClient.solve]
/// stream. Each [SolveEvent] is bridged back through the bloc's own event queue
/// (via [QuestionSolveEventReceived]) so all `emit`s stay sequential and the
/// subscription can be cancelled deterministically on a new submit or on
/// [close].
///
/// Resume / restart policy (v1, A0): there is no resume token. If the stream
/// closes mid-flight without a terminal `done`/`error`, we preserve the partial
/// problem + steps and emit [QuestionInterrupted]; the UI offers a full restart
/// (re-submit the same images) — we do NOT attempt to resume from the last
/// step. A resume token is deferred to a later phase.
class QuestionBloc extends Bloc<QuestionEvent, QuestionState> {
  final SubmitQuestionUseCase submitQuestionUseCase;
  final SolveClient solveClient;
  final QuestionLocalDataSource localDataSource;

  StreamSubscription<SolveEvent>? _solveSubscription;

  // In-flight accumulation for the active solve stream.
  String _currentProblem = '';
  final List<String> _currentSteps = <String>[];
  // True once a terminal `done`/`error` arrived, so a subsequent stream close
  // is NOT treated as a mid-stream interruption.
  bool _terminalReceived = false;

  QuestionBloc({
    required this.submitQuestionUseCase,
    required this.solveClient,
    required this.localDataSource,
  }) : super(QuestionInitial()) {
    on<QuestionSolveRequested>(_onSolveRequested);
    on<QuestionSolveEventReceived>(_onSolveEventReceived);
    on<QuestionSolveStreamClosed>(_onSolveStreamClosed);
    on<QuestionSubmitRequested>(_onQuestionSubmitRequested);
    on<QuestionLoadHistoryRequested>(_onQuestionLoadHistoryRequested);
    on<QuestionDeleteRequested>(_onQuestionDeleteRequested);
  }

  // --- Streaming solve path ------------------------------------------------

  Future<void> _onSolveRequested(
    QuestionSolveRequested event,
    Emitter<QuestionState> emit,
  ) async {
    // Cancel any in-flight stream before starting a new one.
    await _solveSubscription?.cancel();
    _solveSubscription = null;
    _resetSolveState();

    emit(QuestionSolveInProgress());

    // TODO(Phase C): replace the placeholder dev token + hardcoded plan with the
    // real account JWT + entitlement plan resolved from auth. For A0 metering is
    // an abuse/rate guard only and the proxy accepts a dev token.
    const devToken = 'dev-placeholder-token';
    const plan = 'free';

    final stream = solveClient.solve(
      images: event.images,
      subject: event.subject,
      plan: plan,
      token: devToken,
    );

    _solveSubscription = stream.listen(
      (solveEvent) => add(QuestionSolveEventReceived(solveEvent)),
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error('Solve stream error: $error');
        // Surface as a synthetic error event so emit ordering is preserved.
        add(QuestionSolveEventReceived(
          SolveError('stream_error', error.toString()),
        ));
      },
      onDone: () => add(
        QuestionSolveStreamClosed(hadDone: _terminalReceived),
      ),
      cancelOnError: false,
    );
  }

  Future<void> _onSolveEventReceived(
    QuestionSolveEventReceived event,
    Emitter<QuestionState> emit,
  ) async {
    final solveEvent = event.solveEvent;

    switch (solveEvent) {
      case SolveRecognized(:final problem):
        _currentProblem = problem;
        emit(QuestionRecognized(problem));

      case SolveStep(:final content):
        _currentSteps.add(content);
        // Emit an immutable snapshot so equatable/UI sees a new list.
        emit(QuestionStreaming(
          _currentProblem,
          List<String>.unmodifiable(_currentSteps),
        ));

      case SolveDone(:final conclusion, :final model):
        _terminalReceived = true;
        final steps = List<String>.unmodifiable(_currentSteps);
        await _persistAnswer(
          problem: _currentProblem,
          steps: _currentSteps,
          conclusion: conclusion,
          model: model,
          subject: null,
        );
        emit(QuestionAnswered(_currentProblem, steps, conclusion, model));

      case SolveError(:final code, :final message):
        _terminalReceived = true;
        if (code == 'quota_exceeded') {
          emit(QuestionBlocked(message));
        } else {
          AppLogger.error('Solve error [$code]: $message');
          emit(QuestionFailure(message));
        }

      default:
        // Unknown event subtype — ignore rather than crash the stream.
        AppLogger.error('Unhandled solve event: $solveEvent');
    }
  }

  Future<void> _onSolveStreamClosed(
    QuestionSolveStreamClosed event,
    Emitter<QuestionState> emit,
  ) async {
    await _solveSubscription?.cancel();
    _solveSubscription = null;

    if (event.hadDone) {
      // Clean terminal close — terminal state already emitted.
      return;
    }

    // Mid-stream drop: preserve partial progress and offer restart.
    AppLogger.error('Solve stream closed without done (interrupted)');
    emit(QuestionInterrupted(
      _currentProblem,
      List<String>.unmodifiable(_currentSteps),
    ));
  }

  /// Persists a completed Q&A to the existing Hive cache, reusing the
  /// "last 50" trimming behavior of [QuestionLocalDataSource].
  Future<void> _persistAnswer({
    required String problem,
    required List<String> steps,
    required String conclusion,
    required String model,
    required String? subject,
  }) async {
    try {
      final model0 = QuestionResponseModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        question: problem,
        answer: conclusion,
        explanation: steps.join('\n\n'),
        subject: subject,
        createdAt: DateTime.now(),
        metadata: {
          'model': model,
          'steps': steps,
          'source': 'solve_stream',
        },
      );
      await localDataSource.cacheQuestionResponse(model0);
    } catch (e) {
      // Persistence is best-effort; a cache failure must not break the UI flow.
      AppLogger.error('Failed to persist solved question: $e');
    }
  }

  void _resetSolveState() {
    _currentProblem = '';
    _currentSteps.clear();
    _terminalReceived = false;
  }

  // --- Legacy one-shot path (unchanged) ------------------------------------

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

  @override
  Future<void> close() async {
    await _solveSubscription?.cancel();
    solveClient.close();
    return super.close();
  }
}
