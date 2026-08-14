/// Streaming solve events emitted by the proxy `/solve` SSE endpoint.
///
/// Wire contract (see `.omc/handoffs/team-plan.md`):
///   - `{"type":"recognized","problem":"..."}`            -> [SolveRecognized] (first)
///   - `{"type":"step","index":n,"content":"..."}`        -> [SolveStep]
///   - `{"type":"done","conclusion":"...","model":"...",  -> [SolveDone]
///      "metered":true}`
///   - `{"type":"error","code":"...","message":"..."}`    -> [SolveError]
sealed class SolveEvent {
  const SolveEvent();

  /// Dispatches on the `type` discriminator. Throws [FormatException] for an
  /// unknown or missing type so the caller can fail fast on contract drift.
  factory SolveEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    switch (type) {
      case 'recognized':
        return SolveRecognized((json['problem'] as String?) ?? '');
      case 'step':
        return SolveStep(
          (json['index'] as num?)?.toInt() ?? 0,
          (json['content'] as String?) ?? '',
        );
      case 'done':
        return SolveDone(
          (json['conclusion'] as String?) ?? '',
          (json['model'] as String?) ?? '',
          metered: (json['metered'] as bool?) ?? false,
        );
      case 'error':
        return SolveError(
          (json['code'] as String?) ?? 'unknown',
          (json['message'] as String?) ?? '',
        );
      default:
        throw FormatException('Unknown solve event type: $type', json);
    }
  }
}

/// First event: the proxy echoes the recognized problem statement.
class SolveRecognized extends SolveEvent {
  final String problem;
  const SolveRecognized(this.problem);
}

/// An incremental reasoning/solution step. [index] is zero-based and ordered.
class SolveStep extends SolveEvent {
  final int index;
  final String content;
  const SolveStep(this.index, this.content);
}

/// Terminal success event with the final [conclusion] and the [model] used.
/// [metered] indicates the proxy counted this question against the user quota.
class SolveDone extends SolveEvent {
  final String conclusion;
  final String model;
  final bool metered;
  const SolveDone(this.conclusion, this.model, {this.metered = false});
}

/// Terminal failure event. [code] is a stable machine code
/// (e.g. `quota_exceeded`); [message] is human-readable.
class SolveError extends SolveEvent {
  final String code;
  final String message;
  const SolveError(this.code, this.message);
}
