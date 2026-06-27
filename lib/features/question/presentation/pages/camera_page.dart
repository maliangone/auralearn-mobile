import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../../../core/theme/tokens.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/logger.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          '拍题',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        actions: [
          if (_selectedImages.isNotEmpty)
            TextButton(
              onPressed: _proceedToCrop,
              child: Text(
                '下一步 (${_selectedImages.length}/${AppConfig.maxImagesPerQuestion})',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ----------------------------------------------------------------
          // Helper text
          // ----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              '拍下题目，确保清晰可见（最多 ${AppConfig.maxImagesPerQuestion} 张）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          // ----------------------------------------------------------------
          // Selected images preview strip
          // ----------------------------------------------------------------
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
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: AppColors.primary, width: 2),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md - 2),
                          child: Image.file(
                            File(_selectedImages[index].path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius:
                                    BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
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
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
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

          // ----------------------------------------------------------------
          // Primary action cards — exactly two: 拍照 / 从相册选择
          // ----------------------------------------------------------------
          // Content-height, equal-height cards centered in the available space
          // (was a full-height Expanded that stretched the cards top-to-bottom).
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.camera_alt_outlined,
                          label: '拍照',
                          disabled: _isLoading || _atLimit,
                          onTap: () => _captureImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.photo_library_outlined,
                          label: '从相册选择',
                          disabled: _isLoading || _atLimit,
                          onTap: () => _captureImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                ),
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
                child: FilledButton(
                  onPressed: _proceedToCrop,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.base),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    '继续（已选 ${_selectedImages.length} 张）',
                    style:
                        Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                ),
              ),
            ),

          // ----------------------------------------------------------------
          // Text input fallback
          // ----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.lg,
              top: AppSpacing.xs,
            ),
            child: TextButton(
              onPressed: () => context.go('/question'),
              child: Text(
                '改用文字输入',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
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

    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isDenied) {
          _showPermissionDeniedDialog('相机');
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (status.isDenied) {
          _showPermissionDeniedDialog('相册');
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
              '图片过大，请选择小于 ${AppConfig.maxImageSizeMB}MB 的图片。');
          return;
        }
        setState(() => _selectedImages.add(image));
        AppLogger.info('Image captured: ${image.path}');
      }
    } catch (e) {
      AppLogger.error('Error capturing image: $e');
      _showErrorDialog('获取图片失败，请重试。');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  void _proceedToCrop() {
    if (_selectedImages.isEmpty) return;
    context.go('/crop',
        extra: _selectedImages.map((x) => x.path).toList());
  }

  void _showPermissionDeniedDialog(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('需要$name权限'),
        content: Text('请在系统设置中允许访问$name，以便拍题。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('出错了'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('确定')),
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
  final bool disabled;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        disabled ? AppColors.textHint : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xxl,
            horizontal: AppSpacing.base,
          ),
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.surfaceHover
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: disabled ? AppColors.border : AppColors.primary,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: effectiveColor),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                style:
                    Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: effectiveColor,
                          fontWeight: FontWeight.w600,
                        ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
