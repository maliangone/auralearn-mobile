import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:auralearn/core/llm/solve_stream_parser.dart';
import 'package:auralearn/core/network/streaming/solve_event.dart';

/// Drives [SolveStreamParser] the way DirectSolveService does: chunks in,
/// [events] out. Returns the collected events after the chunk stream ends.
Future<List<SolveEvent>> _run(List<String> chunks) async {
  final parser = SolveStreamParser();
  final controller = StreamController<String>();
  final events = <SolveEvent>[];
  final sub = parser.events.listen(events.add);
  final runFuture = parser.run(controller.stream);
  for (final c in chunks) {
    controller.add(c);
  }
  await controller.close();
  await runFuture;
  await sub.cancel();
  return events;
}

void main() {
  group('SolveStreamParser', () {
    test('emits recognized FIRST, then steps, then done LAST', () async {
      final events = await _run([
        'RECOGNIZED: Solve 2x + 3 = 11.\n',
        '1. Subtract 3 from both sides: 2x = 8.\n\n',
        '2. Divide by 2: x = 4.\n\n',
        '结论: x = 4.',
      ]);

      expect(events, hasLength(4));
      expect(events.first, isA<SolveRecognized>());
      expect((events.first as SolveRecognized).problem, 'Solve 2x + 3 = 11.');
      expect(events.last, isA<SolveDone>());

      final steps = events.whereType<SolveStep>().toList();
      expect(steps.map((s) => s.content).toList(), [
        '1. Subtract 3 from both sides: 2x = 8.',
        '2. Divide by 2: x = 4.',
      ]);
      // Step indexes are 0-based and monotonic.
      expect(steps.map((s) => s.index).toList(), [0, 1]);

      final done = events.last as SolveDone;
      expect(done.conclusion, '结论: x = 4.');
    });

    test('recognized is held until the first newline arrives', () async {
      final events = await _run([
        'RECOGNIZED: A',
        'nswer is coming\n',
        'steps here\n\n',
        'done tail',
      ]);
      expect(events.first, isA<SolveRecognized>());
      expect((events.first as SolveRecognized).problem, 'Answer is coming');
    });

    test('model that skips the RECOGNIZED marker: first line is the fallback',
        () async {
      final events = await _run([
        'This problem asks for the value of x.\n',
        'step one\n\n',
        'step two\n\n',
        'x = 5',
      ]);
      expect((events.first as SolveRecognized).problem,
          'This problem asks for the value of x.');
      expect(events.whereType<SolveStep>(), hasLength(2));
    });

    test('empty stream still yields recognized (unavailable) + done fallback',
        () async {
      final events = await _run([]);
      expect(events, hasLength(2));
      expect((events.first as SolveRecognized).problem,
          '(problem read unavailable)');
      expect((events.last as SolveDone).conclusion, 'See steps above.');
    });

    test('stream error becomes a terminal SolveError instead of done',
        () async {
      final parser = SolveStreamParser();
      final controller = StreamController<String>();
      final events = <SolveEvent>[];
      final sub = parser.events.listen(events.add);
      final runFuture = parser.run(controller.stream);
      controller.add('RECOGNIZED: partial read\n');
      controller.addError(Exception('network drop'));
      await controller.close();
      await runFuture;
      await sub.cancel();

      expect(events.last, isA<SolveError>());
      expect((events.last as SolveError).code, 'byok_upstream_error');
    });
  });
}
