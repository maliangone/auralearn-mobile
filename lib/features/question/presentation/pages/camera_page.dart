import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../../../core/theme/tokens.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../l10n/app_localizations.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;

  bool get _atLimit =>
      _selectedImages.length >= AppConfig.maxImagesPerQuestion;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textPrimary,
          tooltip: l.commonBack,
          onPressed: () {
            // Entered via context.go — guard the pop so we never land on an
            // empty stack.
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('home');
            }
          },
        ),
        title: Text(
          l.cameraTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        actions: [
          if (_selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton(
                onPressed: _proceedToCrop,
                child: Text(
                  l.cameraNextWithCount(
                    _selectedImages.length,
                    AppConfig.maxImagesPerQuestion,
                  ),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),

                  // --------------------------------------------------------
                  // Helper text
                  // --------------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Text(
                      l.cameraSubtitle(AppConfig.maxImagesPerQuestion),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // --------------------------------------------------------
                  // Friendly illustration fills what used to be dead space
                  // (hidden once thumbnails take over the strip).
                  // --------------------------------------------------------
                  if (_selectedImages.isEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    SvgPicture.asset(
                      'assets/onboarding/onboarding_capture.svg',
                      width: 180,
                      height: 180,
                    ),
                  ],

                  // --------------------------------------------------------
                  // Selected images preview strip
                  // --------------------------------------------------------
                  if (_selectedImages.isNotEmpty)
                    SizedBox(
                      height: 108,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                          vertical: AppSpacing.sm,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 90,
                            margin: const EdgeInsets.only(
                                right: AppSpacing.sm),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                  color: AppColors.primary, width: 2),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.md - 2),
                                  child: Image.file(
                                    File(_selectedImages[index].path),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  // 44px touch target around the visual dot.
                                  child: Tooltip(
                                    message: l.cameraRemoveImage,
                                    child: InkResponse(
                                      onTap: () => _removeImage(index),
                                      radius: 22,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        margin: const EdgeInsets.all(
                                            AppSpacing.sm),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: AppColors.textOnPrimary,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.sm),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: AppColors.textOnPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  // --------------------------------------------------------
                  // Primary action cards — 拍照 / 从相册选择
                  // --------------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.camera_alt_rounded,
                            label: l.cameraTakePhoto,
                            accent: AppColors.primary,
                            disabled: _isLoading || _atLimit,
                            onTap: () => _captureImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.photo_library_rounded,
                            label: l.cameraFromGallery,
                            accent: AppColors.primaryViolet,
                            disabled: _isLoading || _atLimit,
                            onTap: () => _captureImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Continue button (visible once an image is selected)
          // ----------------------------------------------------------------
          if (_selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToCrop,
                  child: Text(
                    l.cameraContinueWithCount(_selectedImages.length),
                  ),
                ),
              ),
            ),

          // ----------------------------------------------------------------
          // Text input fallback
          // ----------------------------------------------------------------
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.lg,
                top: AppSpacing.xs,
              ),
              child: TextButton(
                onPressed: () => context.go('/question'),
                child: Text(
                  l.cameraUseText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    if (_isLoading || _atLimit) return;

    setState(() => _isLoading = true);

    final l = AppLocalizations.of(context);
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          _showPermissionDeniedDialog(
            l.cameraPermissionCamera,
            permanently: status.isPermanentlyDenied,
          );
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          _showPermissionDeniedDialog(
            l.cameraPermissionGallery,
            permanently: status.isPermanentlyDenied,
          );
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: AppConfig.maxImageWidth.toDouble(),
        maxHeight: AppConfig.maxImageHeight.toDouble(),
        imageQuality: (AppConfig.imageQuality * 100).toInt(),
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        if (fileSize > AppConfig.maxImageSizeMB * 1024 * 1024) {
          _showErrorDialog(
            l.cameraImageTooLarge(AppConfig.maxImageSizeMB),
          );
          return;
        }
        setState(() => _selectedImages.add(image));
        AppLogger.info('Image captured: ${image.path}');
      }
    } catch (e) {
      AppLogger.error('Error capturing image: $e');
      _showErrorDialog(l.cameraImagePickFailed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  void _proceedToCrop() {
    if (_selectedImages.isEmpty) return;
    context.go('/crop',
        extra: _selectedImages.map((x) => x.path).toList());
  }

  void _showPermissionDeniedDialog(String name, {bool permanently = false}) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cameraPermissionNeeded(name)),
        content: Text(l.cameraPermissionRationale(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.commonCancel),
          ),
          // Permanently-denied can only be fixed in system settings; a fresh
          // denial also funnels there for simplicity.
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: Text(l.commonGoSettings),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.commonErrorTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.commonConfirm),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action card — one of the two primary affordances
// ---------------------------------------------------------------------------
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool disabled;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.accent,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = disabled ? AppColors.textHint : accent;

    return AppPressable(
      onTap: disabled ? null : onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppMotion.pressOut,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxl,
          horizontal: AppSpacing.base,
        ),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.surfaceHover
              : accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: disabled ? AppColors.border : accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: disabled ? null : AppShadows.clay(accent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: effectiveColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
