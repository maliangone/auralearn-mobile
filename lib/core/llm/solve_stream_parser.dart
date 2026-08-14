import 'dart:async';

import '../network/streaming/solve_event.dart';
import 'tutor_client.dart';

/// Client-side port of the proxy's `StreamParser`
/// (proxy/src/lib/solve-handler.ts) for BYOK direct mode.
///
/// Consumes raw text chunks from a [Stream] and emits the same ordered
/// [SolveEvent] contract the proxy `/solve` SSE produces:
///   recognized (FIRST) -> step* -> done (LAST).
///
/// Parsing is deliberately tolerant: if the model never emits `RECOGNIZED:`,
/// the first line still becomes the recognized event (best-effort), so the
/// ordering contract always holds.
class SolveStreamParser {
  String _buffer = '';
  bool _recognizedEmitted = false;
  int _stepIndex = 0;
  String _full = '';

  final StreamController<SolveEvent> _controller =
      StreamController<SolveEvent>();
  bool _finished = false;

  /// The event stream. Feed chunks via [push]; call [finish] exactly once
  /// when the model stream ends, then [close] to release resources.
  Stream<SolveEvent> get events => _controller.stream;

  /// Drives the full lifecycle from a chunk stream: pushes every chunk,
  /// finishes on clean end, fails on stream error (auth errors get their own
  /// code), and closes the controller. Completes when [events] is done.
  Future<void> run(Stream<String> chunks) async {
    try {
      await for (final chunk in chunks) {
        push(chunk);
      }
      finish();
    } on TutorClientException catch (e) {
      fail(SolveError(
        e.isAuthError ? 'byok_auth_error' : 'byok_upstream_error',
        e.message,
      ));
    } catch (e) {
      fail(SolveError('byok_upstream_error', 'Direct solve failed: $e'));
    } finally {
      await close();
    }
  }

  /// Feeds one raw text chunk from the model.
  void push(String text) {
    if (_finished) return;
    _full += text;
    _buffer += text;

    if (!_recognizedEmitted) {
      // Wait until we have a full first line (or a clear RECOGNIZED line).
      final newlineIdx = _buffer.indexOf('\n');
      if (newlineIdx == -1) return; // need more
      final firstLine = _buffer.substring(0, newlineIdx).trim();
      final rest = _buffer.substring(newlineIdx + 1);
      final problem = firstLine.replaceFirst(RegExp(r'^RECOGNIZED:\s*', caseSensitive: false), '').trim();
      _emit(SolveRecognized(problem.isEmpty ? '(problem read pending)' : problem));
      _recognizedEmitted = true;
      _buffer = rest;
    }

    _flushSteps();
  }

  void _flushSteps() {
    // Split on blank-line boundaries; keep the last partial segment in the
    // buffer — it is the conclusion tail (see [finish]).
    final parts = _buffer.split(RegExp(r'\n\s*\n'));
    final completeUpTo = parts.length - 1;
    for (var i = 0; i < completeUpTo; i++) {
      final segment = parts[i].trim();
      if (segment.isEmpty) continue;
      _emit(SolveStep(_stepIndex++, segment));
    }
    _buffer = parts.isNotEmpty ? parts.last : '';
  }

  /// Ends the stream: ensures `recognized` was emitted, then emits the
  /// terminal [SolveDone] with the remaining buffer as the conclusion tail.
  ///
  /// Mirrors the proxy: steps are only cut at blank-line boundaries during
  /// [push]; the last un-flushed segment is the conclusion, not a step.
  ///
  /// Returns the conclusion string (also carried by the emitted event).
  String finish() {
    if (_finished) return '';
    _finished = true;

    if (!_recognizedEmitted) {
      final firstLine = _full.split('\n').first.trim();
      _emit(SolveRecognized(
          firstLine.isEmpty ? '(problem read unavailable)' : firstLine));
      _recognizedEmitted = true;
    }

    final tail = _buffer.trim();
    _buffer = '';
    final conclusion = tail.isEmpty ? 'See steps above.' : tail;
    _emit(SolveDone(conclusion, '', metered: false));
    return conclusion;
  }

  /// Emits a terminal error event (replaces `done`).
  void fail(SolveError error) {
    if (_finished) return;
    _finished = true;
    _emit(error);
  }

  void _emit(SolveEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  /// Releases the underlying controller. Call after [finish] / [fail].
  Future<void> close() => _controller.close();
}
