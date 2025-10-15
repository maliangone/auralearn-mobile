import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';
import '../widgets/image_crop_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _cropAreas = List.filled(widget.imagePaths.length, Rect.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Crop Questions (${_currentImageIndex + 1}/${widget.imagePaths.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _submitCroppedImages,
            child: Text(
              'Submit',
              style: TextStyle(
                color: _isProcessing ? Colors.grey : Colors.white,
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
            padding: const EdgeInsets.all(16),
            color: AppTheme.primary.withOpacity(0.1),
            child: Column(
              children: [
                Icon(
                  Icons.crop,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  'Drag the corners to select the question area',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Make sure the entire question is within the blue area',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
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
                  margin: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(16),
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
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentImageIndex == index
                              ? AppTheme.primary
                              : Colors.white30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Navigation buttons
                Row(
                  children: [
                    if (_currentImageIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousImage,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: const Text('Previous'),
                        ),
                      ),
                    
                    if (_currentImageIndex > 0) const SizedBox(width: 16),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing 
                            ? null 
                            : _currentImageIndex < widget.imagePaths.length - 1
                                ? _nextImage
                                : _submitCroppedImages,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _currentImageIndex < widget.imagePaths.length - 1
                                    ? 'Next Image'
                                    : 'Submit Question',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Reset crop button
                TextButton(
                  onPressed: _resetCurrentCrop,
                  child: const Text(
                    'Reset crop area',
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

  void _nextImage() {
    if (_currentImageIndex < widget.imagePaths.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
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

    try {
      // Validate that all images have crop areas defined
      for (int i = 0; i < _cropAreas.length; i++) {
        if (_cropAreas[i] == Rect.zero) {
          _showErrorDialog('Please crop image ${i + 1} before submitting.');
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
      context.go('/question', extra: {
        'images': croppedImageData,
        'hasImages': true,
      });

    } catch (e) {
      AppLogger.error('Error processing cropped images: $e');
      _showErrorDialog('Failed to process images. Please try again.');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
} 