import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/image_crop_widget.dart';

/// Dark-canvas crop screen. The dark surround is intentional (image-editing
/// convention); brand tokens drive the accent colours.
class CropPage extends StatefulWidget {
  final List<String> imagePaths;

  const CropPage({
    super.key,
    required this.imagePaths,
  });

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  late PageController _pageController;
  int _currentImageIndex = 0;
  List<Rect> _cropAreas = [];
  bool _isProcessing = false;

  // Dark canvas palette (deliberate — crop UI reads best on black).
  static const Color _canvas = Colors.black;
  static const Color _onCanvas = Colors.white;
  static final Color _onCanvasMuted =
      Colors.white.withValues(alpha: 0.7);
  static final Color _onCanvasFaint =
      Colors.white.withValues(alpha: 0.3);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _cropAreas = List.filled(widget.imagePaths.length, Rect.zero);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        foregroundColor: _onCanvas,
        title: Text(
          '${l.cropTitle} (${_currentImageIndex + 1}/${widget.imagePaths.length})',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l.commonBack,
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _submitCroppedImages,
            child: Text(
              l.cropSubmit,
              style: TextStyle(
                color: _isProcessing ? _onCanvasFaint : _onCanvas,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.base),
            color: _onCanvas.withValues(alpha: 0.08),
            child: Column(
              children: [
                const Icon(
                  Icons.crop_rounded,
                  color: AppColors.primaryLight,
                  size: 24,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.cropInstruction,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _onCanvas,
                      ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  l.cropInstructionSub,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _onCanvasMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Image cropping area
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: widget.imagePaths.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(AppSpacing.base),
                  child: ImageCropWidget(
                    imagePath: widget.imagePaths[index],
                    initialCropArea: _cropAreas[index],
                    onCropAreaChanged: (cropArea) {
                      _cropAreas[index] = cropArea;
                    },
                  ),
                );
              },
            ),
          ),

          // Navigation and controls
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                children: [
                  // Page indicator
                  if (widget.imagePaths.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.imagePaths.length,
                        (index) => Container(
                          width: _currentImageIndex == index ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? AppColors.primary
                                : _onCanvasFaint,
                            borderRadius:
                                BorderRadius.circular(AppRadius.xs),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.base),

                  // Navigation buttons
                  Row(
                    children: [
                      if (_currentImageIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousImage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _onCanvas,
                              side: BorderSide(color: _onCanvasMuted),
                            ),
                            child: Text(l.onboardingPrevious),
                          ),
                        ),

                      if (_currentImageIndex > 0)
                        const SizedBox(width: AppSpacing.base),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : _currentImageIndex <
                                      widget.imagePaths.length - 1
                                  ? _nextImage
                                  : _submitCroppedImages,
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            AppColors.textOnPrimary),
                                  ),
                                )
                              : Text(
                                  _currentImageIndex <
                                          widget.imagePaths.length - 1
                                      ? l.cropNextImage
                                      : l.cropSubmitQuestion,
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Reset crop button
                  TextButton(
                    onPressed: _resetCurrentCrop,
                    child: Text(
                      l.cropReset,
                      style: TextStyle(color: _onCanvasMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextImage() {
    if (_currentImageIndex < widget.imagePaths.length - 1) {
      _pageController.nextPage(
        duration: AppMotion.staggered,
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      _pageController.previousPage(
        duration: AppMotion.staggered,
        curve: Curves.easeInOut,
      );
    }
  }

  void _resetCurrentCrop() {
    setState(() {
      _cropAreas[_currentImageIndex] = Rect.zero;
    });
  }

  Future<void> _submitCroppedImages() async {
    setState(() {
      _isProcessing = true;
    });

    final l = AppLocalizations.of(context);
    try {
      // Validate that all images have crop areas defined
      for (int i = 0; i < _cropAreas.length; i++) {
        if (_cropAreas[i] == Rect.zero) {
          _showErrorDialog(l.cropErrorUncropped(i + 1));
          return;
        }
      }

      // Prepare cropped image data
      final croppedImageData = <Map<String, dynamic>>[];
      for (int i = 0; i < widget.imagePaths.length; i++) {
        croppedImageData.add({
          'path': widget.imagePaths[i],
          'cropArea': {
            'left': _cropAreas[i].left,
            'top': _cropAreas[i].top,
            'width': _cropAreas[i].width,
            'height': _cropAreas[i].height,
          },
        });
      }

      AppLogger.info('Submitting ${croppedImageData.length} cropped images');

      // Navigate to question submission page with cropped images
      if (mounted) {
        context.go('/question', extra: {
          'images': croppedImageData,
          'hasImages': true,
        });
      }
    } catch (e) {
      AppLogger.error('Error processing cropped images: $e');
      _showErrorDialog(l.cropProcessFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.commonErrorTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.commonConfirm),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
