import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/logger.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Capture Question'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_selectedImages.isNotEmpty)
            TextButton(
              onPressed: _proceedToCrop,
              child: Text(
                'Next (${_selectedImages.length}/${AppConfig.maxImagesPerQuestion})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primary.withOpacity(0.1),
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt,
                  color: AppTheme.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Capture or select up to ${AppConfig.maxImagesPerQuestion} images',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Make sure the question is clearly visible',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Selected images preview
          if (_selectedImages.isNotEmpty) ...[
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary, width: 2),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(_selectedImages[index].path),
                            width: 100,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
          ],

          // Camera actions
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Camera button
                GestureDetector(
                  onTap: _isLoading || _selectedImages.length >= AppConfig.maxImagesPerQuestion
                      ? null
                      : () => _captureImage(ImageSource.camera),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _selectedImages.length >= AppConfig.maxImagesPerQuestion
                          ? Colors.grey
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: _selectedImages.length >= AppConfig.maxImagesPerQuestion
                          ? Colors.grey.shade600
                          : Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Gallery and camera buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: _selectedImages.length >= AppConfig.maxImagesPerQuestion
                          ? null
                          : () => _captureImage(ImageSource.gallery),
                    ),
                    _buildActionButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: _selectedImages.length >= AppConfig.maxImagesPerQuestion
                          ? null
                          : () => _captureImage(ImageSource.camera),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom actions
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _proceedToCrop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Continue with ${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                TextButton(
                  onPressed: () => context.go('/question'),
                  child: const Text(
                    'Type question instead',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDisabled ? Colors.grey.shade800 : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDisabled ? Colors.grey : Colors.white,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isDisabled ? Colors.grey : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDisabled ? Colors.grey : Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    if (_isLoading || _selectedImages.length >= AppConfig.maxImagesPerQuestion) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check permissions
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus.isDenied) {
          _showPermissionDeniedDialog('Camera');
          return;
        }
      }

      if (source == ImageSource.gallery) {
        final storageStatus = await Permission.photos.request();
        if (storageStatus.isDenied) {
          _showPermissionDeniedDialog('Photos');
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
        // Check file size
        final file = File(image.path);
        final fileSize = await file.length();
        
        if (fileSize > AppConfig.maxImageSizeMB * 1024 * 1024) {
          _showErrorDialog('Image is too large. Please select an image smaller than ${AppConfig.maxImageSizeMB}MB.');
          return;
        }

        setState(() {
          _selectedImages.add(image);
        });

        AppLogger.info('Image captured: ${image.path}');
      }
    } catch (e) {
      AppLogger.error('Error capturing image: $e');
      _showErrorDialog('Failed to capture image. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _proceedToCrop() {
    if (_selectedImages.isEmpty) return;

    final imagePaths = _selectedImages.map((image) => image.path).toList();
    context.go('/crop', extra: imagePaths);
  }

  void _showPermissionDeniedDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text('Please allow access to $permission in your device settings to capture images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 