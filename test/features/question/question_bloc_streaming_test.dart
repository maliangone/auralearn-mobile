// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:auralearn/core/error/failures.dart';
import 'package:auralearn/core/network/streaming/solve_client.dart';
import 'package:auralearn/core/network/streaming/solve_event.dart';
import 'package:auralearn/features/question/data/datasources/question_local_data_source.dart';
import 'package:auralearn/features/question/data/models/question_response.dart';
import 'package:auralearn/features/question/domain/entities/question_response.dart';
import 'package:auralearn/features/question/domain/repositories/question_repository.dart';
import 'package:auralearn/features/question/domain/usecases/submit_question_usecase.dart';
import 'package:auralearn/features/question/presentation/bloc/question_bloc.dart';
import 'package:auralearn/features/question/presentation/bloc/question_event.dart';
import 'package:auralearn/features/question/presentation/bloc/question_state.dart';

// ---------------------------------------------------------------------------
// Fakes — plain Dart; no mockito / mocktail needed.
// ---------------------------------------------------------------------------

/// Minimal http.Client stub so SolveClient's super-constructor is satisfied
/// without touching the real network. FakeSolveClient overrides [solve]
/// entirely so this send() is never called.
class _NoOpHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError(
      'FakeSolveClient.solve is overridden; _NoOpHttpClient.send should never be reached.',
    );
  }
}

/// A [SolveClient] whose [solve] method returns whatever stream is assigned to
/// [nextStream] before the call. [closeCallCount] tracks how many times
/// [close] was called.
class FakeSolveClient extends SolveClient {
  Stream<SolveEvent>? nextStream;
  int closeCallCount = 0;

  FakeSolveClient() : super(client: _NoOpHttpClient());

  @override
  Stream<SolveEvent> solve({
    required List<Uint8List> images,
    String? subject,
    String plan = 'free',
    required String token,
    String? context,
  }) {
    return nextStream!;
  }

  @override
  void close() {
    closeCallCount++;
  }
}

/// Records every call to [cacheQuestionResponse] in [cached].
class FakeQuestionLocalDataSource implements QuestionLocalDataSource {
  final List<QuestionResponseModel> cached = [];

  @override
  Future<void> cacheQuestionResponse(QuestionResponseModel questionResponse) async {
    cached.add(questionResponse);
  }

  @override
  Future<List<QuestionResponseModel>> getCachedQuestions() async =>
      List.unmodifiable(cached);

  @override
  Future<QuestionResponseModel?> getLastQuestionResponse() async =>
      cached.lastOrNull;

  @override
  Future<void> clearCache() async => cached.clear();
}

/// Minimal stub for the legacy one-shot path — not exercised by these tests.
class FakeQuestionRepository implements QuestionRepository {
  @override
  Future<Either<Failure, QuestionResponse>> submitQuestion(
    String? content,
    List<Map<String, dynamic>>? images,
  ) async =>
      const Left(ServerFailure('not implemented in fake'));

  @override
  Future<Either<Failure, List<QuestionResponse>>> getQuestionHistory() async =>
      const Left(ServerFailure('not implemented in fake'));

  @override
  Future<Either<Failure, void>> deleteQuestion(String questionId) async =>
      const Left(ServerFailure('not implemented in fake'));
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A minimal valid JPEG header/trailer (1×1 px). FakeSolveClient ignores the
/// bytes, but the bloc passes them through, so they must be non-empty.
Uint8List get _minimalImageBytes => Uint8List.fromList(const <int>[
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9,
    ]);

QuestionBloc _makeBloc({
  required FakeSolveClient solveClient,
  required FakeQuestionLocalDataSource localDataSource,
}) {
  return QuestionBloc(
    submitQuestionUseCase: SubmitQuestionUseCase(FakeQuestionRepository()),
    solveClient: solveClient,
    localDataSource: localDataSource,
  );
}

// ---------------------------------------------------------------------------
// Tests
//
// IMPORTANT ordering rule for BLoC broadcast streams:
//   1. Call expectLater() to attach the listener FIRST.
//   2. Then add the bloc event that will drive the stream.
//   3. Then feed events into the StreamController.
//   4. Await the Future returned by expectLater.
//
// If we add the bloc event before listening, states emitted before the
// listener subscribes are silently dropped.
// ---------------------------------------------------------------------------

void main() {
  group('QuestionBloc — streaming solve path', () {
    late FakeSolveClient fakeClient;
    late FakeQuestionLocalDataSource fakeLocalDs;
    late QuestionBloc bloc;

    setUp(() {
      fakeClient = FakeSolveClient();
      fakeLocalDs = FakeQuestionLocalDataSource();
      bloc = _makeBloc(solveClient: fakeClient, localDataSource: fakeLocalDs);
    });

    tearDown(() async {
      await bloc.close();
    });

    // -------------------------------------------------------------------------
    // Happy path
    // -------------------------------------------------------------------------

    test(
      'happy path: emits QuestionSolveInProgress → QuestionRecognized → '
      'QuestionStreaming (step 1) → QuestionStreaming (step 2) → '
      'QuestionAnswered; persists the conclusion to the local datasource',
      () async {
        final controller = StreamController<SolveEvent>();
        fakeClient.nextStream = controller.stream;

        // Step 1: attach the listener BEFORE adding any events.
        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<QuestionSolveInProgress>(),
            isA<QuestionRecognized>()
                .having((s) => s.problem, 'problem', 'What is 2 + 2?'),
            isA<QuestionStreaming>()
                .having((s) => s.steps, 'steps after step 0', ['First step']),
            isA<QuestionStreaming>().having(
              (s) => s.steps,
              'steps after step 1',
              ['First step', 'Second step'],
            ),
            isA<QuestionAnswered>()
                .having((s) => s.problem, 'problem', 'What is 2 + 2?')
                .having((s) => s.conclusion, 'conclusion', 'The answer is 4.')
                .having(
                  (s) => s.steps,
                  'steps',
                  ['First step', 'Second step'],
                )
                .having((s) => s.model, 'model', 'gpt-4o'),
          ]),
        );

        // Step 2: fire the bloc event that opens the stream subscription.
        bloc.add(QuestionSolveRequested(images: [_minimalImageBytes]));

        // Step 3: drip SSE events in, then close cleanly.
        await Future<void>.delayed(Duration.zero);
        controller.add(const SolveRecognized('What is 2 + 2?'));
        await Future<void>.delayed(Duration.zero);
        controller.add(const SolveStep(0, 'First step'));
        await Future<void>.delayed(Duration.zero);
        controller.add(const SolveStep(1, 'Second step'));
        await Future<void>.delayed(Duration.zero);
        controller.add(const SolveDone('The answer is 4.', 'gpt-4o'));
        await Future<void>.delayed(Duration.zero);
        await controller.close();

        // Step 4: wait for all expected states.
        await expectation;

        // Persistence assertions.
        expect(fakeLocalDs.cached, hasLength(1),
            reason: 'completed Q&A must be persisted exactly once');
        final saved = fakeLocalDs.cached.first;
        expect(saved.question, 'What is 2 + 2?',
            reason: 'persisted question must match recognized problem');
        expect(saved.answer, 'The answer is 4.',
            reason: 'persisted answer must match SolveDone conclusion');
        expect(
          (saved.metadata?['steps'] as List?)?.cast<String>(),
          ['First step', 'Second step'],
          reason: 'persisted steps metadata must contain all streaming steps',
        );
      },
    );

    // -------------------------------------------------------------------------
    // Quota path
    // -------------------------------------------------------------------------

    test(
      'quota path: SolveError(quota_exceeded) emits QuestionBlocked with '
      'the server message; nothing is persisted',
      () async {
        final controller = StreamController<SolveEvent>();
        fakeClient.nextStream = controller.stream;

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<QuestionSolveInProgress>(),
            isA<QuestionBlocked>()
                .having((s) => s.message, 'message', 'Daily limit reached'),
          ]),
        );

        bloc.add(QuestionSolveRequested(images: [_minimalImageBytes]));
        await Future<void>.delayed(Duration.zero);
        controller.add(const SolveError('quota_exceeded', 'Daily limit reached'));
        await controller.close();

        await expectation;

        expect(fakeLocalDs.cached, isEmpty,
            reason: 'quota errors must not trigger persistence');
      },
    );

    // -------------------------------------------------------------------------
    // Generic error path
    // -------------------------------------------------------------------------

    test(
      'generic error: SolveError(upstream_error) emits QuestionFailure with '
      'the server message; nothing is persisted',
      () async {
        final controller = StreamController<SolveEvent>();
        fakeClient.nextStream = controller.stream;

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<QuestionSolveInProgress>(),
            isA<QuestionFailure>()
                .having((s) => s.message, 'message', 'Model unavailable'),
          ]),
        );

        bloc.add(QuestionSolveRequested(images: [_minimalImageBytes]));
        await Future<void>.delayed(Duration.zero);
        controller.add(const SolveError('upstream_error', 'Model unavailable'));
        await controller.close();

        await expectation;

        expect(fakeLocalDs.cached, isEmpty,
            reason: 'generic errors must not trigger persistence');
      },
    );

    // -------------------------------------------------------------------------
    // Interruption path (mid-stream close without done/error)
    // -------------------------------------------------------------------------

    test(
      'interruption: stream closed without SolveDone or SolveError after '
      'SolveRecognized + SolveStep emits QuestionInterrupted with partial '
      'problem and steps preserved; nothing is persisted',
      () async {
        final controller = StreamController<SolveEvent>();
        fakeClient.nextStream = controller.stream;

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<QuestionSolveInProgress>(),
            isA<QuestionRecognized>()
                .having((s) => s.problem, 'problem', 'Partial problem text'),
            isA<QuestionStreaming>().having(
              (s) => s.steps,
              'steps',
              ['Only step before drop'],
            ),
            isA<QuestionInterrupted>()
                .having(
                  (s) => s.partialProblem,
                  'partialProblem',
                  'Partial problem text',
                )
                .having(
                  (s) => s.partialSteps,
                  'partialSteps',
                  ['Only step before drop'],
                ),
          ]),
        );

        bloc.add(QuestionSolveRequested(images: [_minimalImageBytes]));
        await Future<void>.delayed(Duration.zero);
        controller.add(const SolveRecognized('Partial problem text'));
        await Future<void>.delayed(Duration.zero);
        controller.add(const SolveStep(0, 'Only step before drop'));
        await Future<void>.delayed(Duration.zero);
        // Close without a terminal event — simulates network drop.
        await controller.close();

        await expectation;

        expect(fakeLocalDs.cached, isEmpty,
            reason: 'interrupted streams must not trigger persistence');
      },
    );
  });
}
