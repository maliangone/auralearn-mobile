import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/network/streaming/solve_client.dart';
import '../../../../core/network/streaming/solve_event.dart';
import '../../../../core/theme/tokens.dart';
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
  final SolveClient _client = SolveClient();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Turn> _turns = [];
  StreamSubscription<SolveEvent>? _sub;
  bool _busy = false;

  // TODO(integration): use the real account JWT from auth instead of this dev
  // placeholder once the accounts->proxy token exchange is wired (Phase C).
  static const String _devToken = 'dev-placeholder-token';

  @override
  void dispose() {
    _sub?.cancel();
    _client.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final q = _input.text.trim();
    if (q.isEmpty || _busy) return;
    if (!widget.document.hasText) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这份资料没有可提问的文本内容')),
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
    _sub = _client
        .solve(
          images: const <Uint8List>[],
          subject: null,
          token: _devToken,
          context: widget.document.content,
        )
        .listen(
          (event) => _onEvent(turn, event),
          onError: (Object e) => _finish(turn, error: '出错了：$e'),
          onDone: () {
            // Stream closed without a terminal done => interrupted.
            if (!turn.done) _finish(turn, error: '回答中断，请重试');
          },
        );
  }

  void _onEvent(_Turn turn, SolveEvent event) {
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
              ? '今日免费额度已用完（每天 3 题），升级后可继续'
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
        title: Text(widget.document.title, overflow: TextOverflow.ellipsis),
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
                    itemBuilder: (context, i) => _TurnView(turn: _turns[i]),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text(
          '针对这份资料提问，AI 家教会结合资料内容一步步讲解',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _TurnView extends StatelessWidget {
  final _Turn turn;
  const _TurnView({required this.turn});

  @override
  Widget build(BuildContext context) {
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
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(turn.question,
                style: const TextStyle(color: AppColors.textOnPrimary)),
          ),
        ),
        // Answer.
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg, right: 24),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < turn.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text('${i + 1}. ${turn.steps[i]}',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary)),
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
                  child: Text('结论：${turn.conclusion}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
              ],
              if (turn.error != null)
                Text(turn.error!,
                    style: const TextStyle(color: AppColors.error)),
              if (!turn.done &&
                  turn.steps.isEmpty &&
                  turn.conclusion == null &&
                  turn.error == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
                  hintText: '针对这份资料提问…',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
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
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
