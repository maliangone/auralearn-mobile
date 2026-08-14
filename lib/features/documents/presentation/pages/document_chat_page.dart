import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/llm/solve_service.dart';
import '../../../../core/network/streaming/solve_event.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/document.dart';

/// 向这份资料提问 — a simple chat over an imported [Document]. Each question is
/// sent to the proxy `/solve` with the document text as `context`
/// (context-stuffing, no RAG) and the streamed answer is rendered live.
class DocumentChatPage extends StatefulWidget {
  final Document document;
  const DocumentChatPage({super.key, required this.document});

  @override
  State<DocumentChatPage> createState() => _DocumentChatPageState();
}

class _DocumentChatPageState extends State<DocumentChatPage> {
  // Factory-registered: each page gets its own transport, closed on dispose.
  final SolveService _service = getIt<SolveService>();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Turn> _turns = [];
  StreamSubscription<SolveEvent>? _sub;
  bool _busy = false;

  @override
  void dispose() {
    _sub?.cancel();
    _service.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Sends a question. When [preset] is given (error-turn retry), it is sent
  /// instead of the input field's current text.
  void _send([String? preset]) {
    final l = AppLocalizations.of(context);
    final q = (preset ?? _input.text).trim();
    if (q.isEmpty || _busy) return;
    if (!widget.document.hasText) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.docsNoText)),
      );
      return;
    }
    _input.clear();
    final turn = _Turn(question: q);
    setState(() {
      _turns.add(turn);
      _busy = true;
    });
    _scrollToEnd();

    _sub?.cancel();
    _sub = _service
        .solve(
          images: const <Uint8List>[],
          subject: null,
          text: q,
          context: widget.document.content,
        )
        .listen(
          (event) => _onEvent(turn, event),
          onError: (Object e) =>
              _finish(turn, error: l.commonErrorWithMessage('$e')),
          onDone: () {
            // Stream closed without a terminal done => interrupted.
            if (!turn.done) _finish(turn, error: l.docsAnswerInterrupted);
          },
        );
  }

  void _onEvent(_Turn turn, SolveEvent event) {
    final l = AppLocalizations.of(context);
    setState(() {
      switch (event) {
        case SolveRecognized():
          // No image here; ignore any recognized echo.
          break;
        case SolveStep(:final content):
          turn.steps.add(content);
        case SolveDone(:final conclusion):
          turn.conclusion = conclusion;
          turn.done = true;
          _busy = false;
        case SolveError(:final code, :final message):
          turn.done = true;
          _busy = false;
          turn.error = code == 'quota_exceeded'
              ? l.docsQuotaUsedUp(AppConfig.freeDailyQuota)
              : message;
      }
    });
    _scrollToEnd();
  }

  void _finish(_Turn turn, {required String error}) {
    setState(() {
      turn.done = true;
      turn.error = error;
      _busy = false;
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.document.title,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _turns.isEmpty
                ? const _Hint()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.base),
                    itemCount: _turns.length,
                    itemBuilder: (context, i) {
                      final turn = _turns[i];
                      return _TurnView(
                        turn: turn,
                        onRetry: turn.error != null
                            ? () => _send(turn.question)
                            : null,
                      );
                    },
                  ),
          ),
          _InputBar(controller: _input, busy: _busy, onSend: _send),
        ],
      ),
    );
  }
}

class _Turn {
  final String question;
  final List<String> steps = [];
  String? conclusion;
  String? error;
  bool done = false;
  _Turn({required this.question});
}

class _Hint extends StatelessWidget {
  const _Hint();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          l.docsAskSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _TurnView extends StatelessWidget {
  final _Turn turn;

  /// Re-sends this turn's question through the same send path; shown only for
  /// turns that ended in an error.
  final VoidCallback? onRetry;

  const _TurnView({required this.turn, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question bubble (right-aligned).
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm, left: 48),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Text(
              turn.question,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textOnPrimary),
            ),
          ),
        ),
        // Answer.
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg, right: 24),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < turn.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '${i + 1}. ${turn.steps[i]}',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              if (turn.conclusion != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.encourageLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    '${l.questionConclusion}: ${turn.conclusion}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
              if (turn.error != null) ...[
                Text(
                  turn.error!,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.error),
                ),
                if (onRetry != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(l.commonRetry),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ),
              ],
              if (!turn.done &&
                  turn.steps.isEmpty &&
                  turn.conclusion == null &&
                  turn.error == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;
  const _InputBar(
      {required this.controller, required this.busy, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.base),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: l.docsAskHint,
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: busy ? null : onSend,
              tooltip: l.commonSubmit,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
