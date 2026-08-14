import 'dart:typed_data';

import 'package:equatable/equatable.dart';

abstract class QuestionEvent extends Equatable {
  const QuestionEvent();

  @override
  List<Object?> get props => [];
}

/// Legacy one-shot submit (Retrofit/use-case AI path). Kept intact so
/// non-streaming callers continue to work; the streaming flow uses
/// [QuestionSolveRequested] instead.
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

/// Streaming solve request: carries the captured image bytes (≤3) plus an
/// optional subject hint. Drives [SolveClient.solve] and emits incremental
/// streaming states (recognized → streaming → answered / blocked / failure /
/// interrupted).
class QuestionSolveRequested extends QuestionEvent {
  final List<Uint8List> images;
  final String? subject;

  const QuestionSolveRequested({
    required this.images,
    this.subject,
  });

  @override
  List<Object?> get props => [images, subject];
}

/// Internal event used to bridge each [SolveEvent] from the async stream back
/// onto the bloc's single-threaded event queue, so emits stay sequential and
/// the subscription can be cancelled cleanly.
class QuestionSolveEventReceived extends QuestionEvent {
  final dynamic solveEvent;

  const QuestionSolveEventReceived(this.solveEvent);

  @override
  List<Object?> get props => [solveEvent];
}

/// Internal event signalling the solve stream closed. [hadDone] distinguishes a
/// clean terminal close (a `done`/`error` already arrived) from a mid-stream
/// network drop (which must surface as [QuestionInterrupted]).
class QuestionSolveStreamClosed extends QuestionEvent {
  final bool hadDone;

  const QuestionSolveStreamClosed({required this.hadDone});

  @override
  List<Object?> get props => [hadDone];
}

class QuestionLoadHistoryRequested extends QuestionEvent {}

class QuestionDeleteRequested extends QuestionEvent {
  final String questionId;

  const QuestionDeleteRequested({required this.questionId});

  @override
  List<Object?> get props => [questionId];
}
