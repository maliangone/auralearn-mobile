import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/logger.dart';
import '../../../flashcards/domain/usecases/create_flashcard_from_history_usecase.dart';
import '../bloc/question_bloc.dart';
import '../bloc/question_event.dart';
import '../bloc/question_state.dart';
import '../widgets/question_input_widget.dart';

/// Phase A0 question screen.
///
/// Two paths share this page:
///   - Streaming solve: launched when the camera→crop flow hands off captured
///     image paths via `initialData['images']`. The image files are read into
///     `Uint8List` bytes and dispatched as [QuestionSolveRequested], then the
///     streaming states (recognized → streaming → answered / blocked /
///     interrupted / failure) render functionally with theme tokens.
///   - Legacy text submit: the typed-question fallback still dispatches the
///     one-shot [QuestionSubmitRequested] and surfaces the legacy success state.
class QuestionPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const QuestionPage({
    super.key,
    this.initialData,
  });

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// File paths for the images currently driving the solve flow. Held so a
  /// "重新解答" / retake restart can re-dispatch the same images.
  List<String> _imagePaths = const [];

  /// Decoded bytes of [_imagePaths], cached so a restart does not re-read disk.
  List<Uint8List> _imageBytes = const [];

  /// True while we are reading image files off disk before the stream starts.
  bool _preparingImages = false;

  /// The legacy text-submit answer, if any (kept so the typed-question fallback
  /// remains usable). Null until a one-shot submit succeeds.
  String? _legacyAnswer;
  bool _legacySubmitting = false;

  bool get _hasImages => _imagePaths.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _extractInitialImages();
    if (_hasImages) {
      // Kick off the streaming solve once the first frame is mounted so the
      // bloc context is available.
      WidgetsBinding.instance.addPostFrameCallback((_) => _startSolve());
    }
  }

  void _extractInitialImages() {
    final images = widget.initialData?['images'];
    if (images is List) {
      _imagePaths = images
          .whereType<Map>()
          .map((m) => m['path'])
          .whereType<String>()
          .toList(growable: false);
    }
  }

  /// Reads the selected image files into bytes and dispatches the solve request.
  Future<void> _startSolve() async {
    if (_imagePaths.isEmpty) return;

    setState(() => _preparingImages = true);
    try {
      final bytes = <Uint8List>[];
      for (final path in _imagePaths) {
        bytes.add(await File(path).readAsBytes());
      }
      if (!mounted) return;
      _imageBytes = bytes;
      context.read<QuestionBloc>().add(
            QuestionSolveRequested(images: bytes, subject: null),
          );
    } catch (e) {
      AppLogger.error('Failed to read captured images: $e');
      if (mounted) {
        _showErrorSnackBar('无法读取图片，请重新拍摄。');
      }
    } finally {
      if (mounted) setState(() => _preparingImages = false);
    }
  }

  /// Restarts the solve with the same images (interrupted / retry paths).
  void _restartSolve() {
    if (_imageBytes.isNotEmpty) {
      context.read<QuestionBloc>().add(
            QuestionSolveRequested(images: _imageBytes, subject: null),
          );
    } else {
      _startSolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('解题'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: '拍照',
            onPressed: () => context.go('/camera'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '历史',
            onPressed: () => context.go('/history'),
          ),
        ],
      ),
      body: _hasImages ? _buildSolveBody() : _buildLegacyBody(),
    );
  }

  // --- Streaming solve UI ---------------------------------------------------

  Widget _buildSolveBody() {
    return BlocBuilder<QuestionBloc, QuestionState>(
      builder: (context, state) {
        if (_preparingImages || state is QuestionSolveInProgress) {
          return _SolveScaffold(
            children: [
              const _RecognizingBanner(),
              const SizedBox(height: AppSpacing.xl),
              _centeredLoader('正在识别题目…'),
            ],
          );
        }

        if (state is QuestionRecognized) {
          return _SolveScaffold(
            children: [
              const _RecognizedBanner(),
              const SizedBox(height: AppSpacing.md),
              _ProblemCard(problem: state.problem),
              const SizedBox(height: AppSpacing.xl),
              _centeredLoader('正在解答…'),
              const SizedBox(height: AppSpacing.lg),
              _retakeRow(),
            ],
          );
        }

        if (state is QuestionStreaming) {
          return _SolveScaffold(
            children: [
              const _RecognizedBanner(),
              const SizedBox(height: AppSpacing.md),
              _ProblemCard(problem: state.problem),
              const SizedBox(height: AppSpacing.lg),
              _StepsList(steps: state.steps, streaming: true),
            ],
          );
        }

        if (state is QuestionAnswered) {
          return _SolveScaffold(
            children: [
              _ProblemCard(problem: state.problem),
              const SizedBox(height: AppSpacing.lg),
              _StepsList(steps: state.steps, streaming: false),
              const SizedBox(height: AppSpacing.lg),
              _ConclusionCard(conclusion: state.conclusion, model: state.model),
              const SizedBox(height: AppSpacing.lg),
              _AddToErrorBookButton(answered: state),
              const SizedBox(height: AppSpacing.sm),
              _retakeRow(),
            ],
          );
        }

        if (state is QuestionBlocked) {
          return _SolveScaffold(
            children: [_UpgradePrompt(message: state.message)],
          );
        }

        if (state is QuestionInterrupted) {
          return _SolveScaffold(
            children: [
              if (state.partialProblem.isNotEmpty) ...[
                _ProblemCard(problem: state.partialProblem),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (state.partialSteps.isNotEmpty) ...[
                _StepsList(steps: state.partialSteps, streaming: false),
                const SizedBox(height: AppSpacing.lg),
              ],
              _InterruptedCard(onRestart: _restartSolve),
            ],
          );
        }

        if (state is QuestionFailure) {
          return _SolveScaffold(
            children: [
              _FailureCard(message: state.message, onRetry: _restartSolve),
            ],
          );
        }

        // QuestionInitial or any legacy state while in image mode: show a
        // neutral loader until the post-frame solve dispatch lands.
        return _SolveScaffold(
          children: [
            const _RecognizingBanner(),
            const SizedBox(height: AppSpacing.xl),
            _centeredLoader('正在识别题目…'),
          ],
        );
      },
    );
  }

  Widget _centeredLoader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _retakeRow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => context.go('/camera'),
        icon: const Icon(Icons.camera_alt_outlined, size: 18),
        label: const Text('重新拍摄'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }

  // --- Legacy text-submit fallback ------------------------------------------

  Widget _buildLegacyBody() {
    return BlocListener<QuestionBloc, QuestionState>(
      listener: (context, state) {
        if (state is QuestionSubmitSuccess) {
          setState(() {
            _legacySubmitting = false;
            _legacyAnswer = state.response.answer ?? '暂无解答';
          });
          _scrollToBottom();
        } else if (state is QuestionSubmitFailure) {
          setState(() => _legacySubmitting = false);
          _showErrorSnackBar(state.message);
        } else if (state is QuestionSubmitInProgress) {
          setState(() => _legacySubmitting = true);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                const _LegacyWelcome(),
                if (_legacySubmitting) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _centeredLoader('正在解答…'),
                ],
                if (_legacyAnswer != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ConclusionCard(conclusion: _legacyAnswer!, model: ''),
                ],
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: QuestionInputWidget(
              controller: _textController,
              focusNode: _focusNode,
              onSubmit: _submitTextQuestion,
              onAttachImage: () => context.go('/camera'),
              isLoading: _legacySubmitting,
            ),
          ),
        ],
      ),
    );
  }

  void _submitTextQuestion(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    context.read<QuestionBloc>().add(
          QuestionSubmitRequested(content: trimmed, images: null),
        );
    _textController.clear();
  }

  // --- Helpers --------------------------------------------------------------

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Presentational pieces
// ---------------------------------------------------------------------------

/// Scrollable padded column shared by all solve states.
class _SolveScaffold extends StatelessWidget {
  final List<Widget> children;
  const _SolveScaffold({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: children,
    );
  }
}

class _RecognizingBanner extends StatelessWidget {
  const _RecognizingBanner();

  @override
  Widget build(BuildContext context) {
    return const _Banner(
      icon: Icons.image_search,
      color: AppColors.primary,
      bg: AppColors.primaryLight,
      label: '正在识别题目',
    );
  }
}

class _RecognizedBanner extends StatelessWidget {
  const _RecognizedBanner();

  @override
  Widget build(BuildContext context) {
    return const _Banner(
      icon: Icons.check_circle_outline,
      color: AppColors.primary,
      bg: AppColors.primaryLight,
      label: '识别到的题目',
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;

  const _Banner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  final String problem;
  const _ProblemCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        problem.isEmpty ? '（未识别到题目文本）' : problem,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }
}

class _StepsList extends StatelessWidget {
  final List<String> steps;
  final bool streaming;

  const _StepsList({required this.steps, required this.streaming});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            '解题步骤',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        for (int i = 0; i < steps.length; i++)
          _StepTile(index: i + 1, content: steps[i]),
        if (streaming)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final int index;
  final String content;

  const _StepTile({required this.index, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConclusionCard extends StatelessWidget {
  final String conclusion;
  final String model;

  const _ConclusionCard({required this.conclusion, required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.encourageLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.encourage.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded,
                  size: 18, color: AppColors.encourage),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '结论',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            conclusion.isEmpty ? '（无结论）' : conclusion,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (model.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '由 $model 解答',
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "加入错题本" — saves the answered problem as a spaced-repetition flashcard.
///
/// Resolves [CreateFlashcardFromHistoryUseCase] from the service locator (the
/// QuestionBloc does not own it). DI wiring for that use case must be registered
/// in `injection_container.dart` (see the integration notes returned by this
/// task); until then this resolution throws and is caught into an error
/// SnackBar. The front is the recognized problem; the back is the conclusion
/// followed by the numbered solution steps.
class _AddToErrorBookButton extends StatefulWidget {
  final QuestionAnswered answered;
  const _AddToErrorBookButton({required this.answered});

  @override
  State<_AddToErrorBookButton> createState() => _AddToErrorBookButtonState();
}

class _AddToErrorBookButtonState extends State<_AddToErrorBookButton> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _add() async {
    if (_saving || _saved) return;
    setState(() => _saving = true);

    final a = widget.answered;
    final back = _buildBack(a);
    // The persisted history id is not exposed on QuestionAnswered, so we derive
    // a stable best-effort source reference from the problem text. The card's
    // own id is a fresh uuid generated in the data source.
    final sourceId = 'q_${a.problem.hashCode}';

    try {
      final useCase = getIt<CreateFlashcardFromHistoryUseCase>();
      final result = await useCase(CreateFlashcardFromHistoryParams(
        sourceHistoryId: sourceId,
        front: a.problem,
        back: back,
      ));
      if (!mounted) return;
      result.fold(
        (failure) {
          setState(() => _saving = false);
          _showSnack('加入失败：${failure.message}', AppColors.error);
        },
        (_) {
          setState(() {
            _saving = false;
            _saved = true;
          });
          _showSnack('已加入错题本', AppColors.encourage);
        },
      );
    } catch (e) {
      AppLogger.error('Add to error-book failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('加入失败，请稍后再试', AppColors.error);
    }
  }

  /// Back of the card = conclusion + numbered steps.
  String _buildBack(QuestionAnswered a) {
    final buffer = StringBuffer();
    if (a.conclusion.isNotEmpty) {
      buffer.writeln('结论：${a.conclusion}');
    }
    if (a.steps.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('解题步骤：');
      for (var i = 0; i < a.steps.length; i++) {
        buffer.writeln('${i + 1}. ${a.steps[i]}');
      }
    }
    return buffer.toString().trim();
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _saved ? null : (_saving ? null : _add),
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Icon(
                _saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
                size: 18,
              ),
        label: Text(_saved ? '已加入错题本' : '加入错题本'),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              _saved ? AppColors.encourage : AppColors.primary,
          side: BorderSide(
            color: _saved ? AppColors.encourage : AppColors.primary,
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}

class _UpgradePrompt extends StatelessWidget {
  final String message;
  const _UpgradePrompt({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_outlined,
              size: 40, color: AppColors.warning),
          const SizedBox(height: AppSpacing.md),
          Text(
            '今日免费额度已用完（3/天）',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            '升级解锁更多解题次数',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.base - 2),
              ),
              child: const Text(
                '立即升级',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterruptedCard extends StatelessWidget {
  final VoidCallback onRestart;
  const _InterruptedCard({required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4,
              size: 32, color: AppColors.warning),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '解答中断了，连接似乎断开。',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重新解答'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.base - 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailureCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            message.isEmpty ? '解答失败，请重试。' : message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.base - 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyWelcome extends StatelessWidget {
  const _LegacyWelcome();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        '输入你的问题，或点击相机拍下题目。',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }
}
