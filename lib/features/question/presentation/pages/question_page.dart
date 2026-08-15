import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/tutor_markdown.dart';
import '../../../../l10n/app_localizations.dart';
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
        _showErrorSnackBar(AppLocalizations.of(context).cameraImageReadFailed);
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
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.questionTitle),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: l.cameraTakePhoto,
            onPressed: () => context.go('/camera'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l.navHistory,
            onPressed: () => context.go('/history'),
          ),
        ],
      ),
      body: _hasImages ? _buildSolveBody() : _buildLegacyBody(),
    );
  }

  // --- Streaming solve UI ---------------------------------------------------

  Widget _buildSolveBody() {
    final l = AppLocalizations.of(context);
    return BlocBuilder<QuestionBloc, QuestionState>(
      builder: (context, state) {
        if (_preparingImages || state is QuestionSolveInProgress) {
          return _SolveScaffold(
            children: [
              const _RecognizingBanner(),
              const SizedBox(height: AppSpacing.xl),
              _centeredLoader(l.questionRecognizing),
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
              _centeredLoader(l.questionSolving),
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
            _centeredLoader(l.questionRecognizing),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _retakeRow() {
    final l = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => context.go('/camera'),
        icon: const Icon(Icons.camera_alt_outlined, size: 18),
        label: Text(l.questionRetake),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }

  // --- Legacy text-submit fallback ------------------------------------------

  Widget _buildLegacyBody() {
    final l = AppLocalizations.of(context);
    return BlocListener<QuestionBloc, QuestionState>(
      listener: (context, state) {
        if (state is QuestionSubmitSuccess) {
          setState(() {
            _legacySubmitting = false;
            _legacyAnswer = state.response.answer ?? l.questionNoAnswer;
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
                _LegacyWelcome(
                  onSampleTap: (sample) {
                    _textController.text = sample;
                    _textController.selection = TextSelection.collapsed(
                      offset: sample.length,
                    );
                    _focusNode.requestFocus();
                  },
                ),
                if (_legacySubmitting) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _centeredLoader(l.questionSolving),
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
    final l = AppLocalizations.of(context);
    return _Banner(
      icon: Icons.image_search,
      color: AppColors.primary,
      bg: AppColors.primaryLight,
      label: l.questionRecognizing,
    );
  }
}

class _RecognizedBanner extends StatelessWidget {
  const _RecognizedBanner();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Banner(
      icon: Icons.check_circle_outline,
      color: AppColors.primary,
      bg: AppColors.primaryLight,
      label: l.questionRecognized,
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
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
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
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: TutorMarkdown(
        problem.isEmpty ? l.questionNoTextRecognized : problem,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            l.questionSteps,
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
            child: TutorMarkdown(
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
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.encourageLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
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
                l.questionConclusion,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TutorMarkdown(
            conclusion.isEmpty ? l.questionNoConclusion : conclusion,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (model.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l.questionSolvedBy(model),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
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

    final l = AppLocalizations.of(context);
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
          AppLogger.error('Add to error-book failed: ${failure.message}');
          _showSnack(l.questionAddFailed, AppColors.error);
        },
        (_) {
          setState(() {
            _saving = false;
            _saved = true;
          });
          _showSnack(l.questionAddedToErrorBook, AppColors.encourage);
        },
      );
    } catch (e) {
      AppLogger.error('Add to error-book failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack(l.questionAddFailed, AppColors.error);
    }
  }

  /// Back of the card = conclusion + numbered steps.
  String _buildBack(QuestionAnswered a) {
    final l = AppLocalizations.of(context);
    final buffer = StringBuffer();
    if (a.conclusion.isNotEmpty) {
      buffer.writeln('${l.questionConclusion}: ${a.conclusion}');
    }
    if (a.steps.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('${l.questionSteps}:');
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
    final l = AppLocalizations.of(context);
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
        label:
            Text(_saved ? l.questionAddedToErrorBook : l.questionAddToErrorBook),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              _saved ? AppColors.encourage : AppColors.primary,
          side: BorderSide(
            color: _saved ? AppColors.encourage : AppColors.primary,
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
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
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_outlined,
              size: 40, color: AppColors.warning),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.questionQuotaUsedUp(AppConfig.freeDailyQuota),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.questionQuotaUpgradeHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: Text(
                l.questionUpgradeNow,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4,
              size: 32, color: AppColors.warning),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.questionInterrupted,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.questionRetrySolve),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.base - 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
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
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            message.isEmpty ? l.questionSolveFailed : message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.commonRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.base - 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyWelcome extends StatelessWidget {
  /// Called when a sample-question chip is tapped — fills the input field.
  final ValueChanged<String>? onSampleTap;

  const _LegacyWelcome({this.onSampleTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final samples = [l.questionSample1, l.questionSample2, l.questionSample3];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand illustration + hint card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              SvgPicture.asset(
                'assets/illustrations/question_empty.svg',
                width: 140,
                height: 140,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l.questionEmptyHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Sample questions — one tap drops the text into the input field.
        Text(
          l.questionTryThese,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final sample in samples)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: InkWell(
              onTap: () => onSampleTap?.call(sample),
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        sample,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
