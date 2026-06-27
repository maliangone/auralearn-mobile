import 'package:equatable/equatable.dart';
import '../../domain/entities/question_response.dart';

abstract class QuestionState extends Equatable {
  const QuestionState();

  @override
  List<Object?> get props => [];
}

class QuestionInitial extends QuestionState {}

// ---------------------------------------------------------------------------
// Streaming solve states (Phase A0)
// ---------------------------------------------------------------------------

/// Emitted immediately after a [QuestionSolveRequested] while waiting for the
/// first event from the proxy.
class QuestionSolveInProgress extends QuestionState {}

/// The proxy echoed the recognized problem. Surfaced so the UI can show the
/// read-back problem and let the user confirm or retake before the answer
/// streams in.
class QuestionRecognized extends QuestionState {
  final String problem;

  const QuestionRecognized(this.problem);

  @override
  List<Object?> get props => [problem];
}

/// Steps are streaming in. [steps] is the ordered accumulation so far; a new
/// instance is emitted on every [SolveStep] so the UI rebuilds incrementally.
class QuestionStreaming extends QuestionState {
  final String problem;
  final List<String> steps;

  const QuestionStreaming(this.problem, this.steps);

  @override
  List<Object?> get props => [problem, steps];
}

/// Terminal success: all steps received plus the final [conclusion] from
/// [model]. The completed Q&A has been persisted to the Hive cache.
class QuestionAnswered extends QuestionState {
  final String problem;
  final List<String> steps;
  final String conclusion;
  final String model;

  const QuestionAnswered(
    this.problem,
    this.steps,
    this.conclusion,
    this.model,
  );

  @override
  List<Object?> get props => [problem, steps, conclusion, model];
}

/// Terminal: the free daily quota (3/day) was reached. The UI should prompt an
/// upgrade. Distinct from [QuestionFailure] so the upsell path is explicit.
class QuestionBlocked extends QuestionState {
  final String message;

  const QuestionBlocked(this.message);

  @override
  List<Object?> get props => [message];
}

/// Terminal failure for any non-quota error (network, server, contract).
class QuestionFailure extends QuestionState {
  final String message;

  const QuestionFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Terminal: the stream closed mid-flight without a `done` (network drop /
/// server hang-up). Preserves whatever partial problem/steps arrived. v1
/// resume policy = restart only (no resume token); see QuestionBloc.
class QuestionInterrupted extends QuestionState {
  final String partialProblem;
  final List<String> partialSteps;

  const QuestionInterrupted(this.partialProblem, this.partialSteps);

  @override
  List<Object?> get props => [partialProblem, partialSteps];
}

// ---------------------------------------------------------------------------
// Legacy one-shot states (Retrofit/use-case AI path) — kept intact.
// ---------------------------------------------------------------------------

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
