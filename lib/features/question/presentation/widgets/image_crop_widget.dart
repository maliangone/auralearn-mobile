import 'package:flutter/material.dart';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';

class ImageCropWidget extends StatefulWidget {
  final String imagePath;
  final Rect initialCropArea;
  final Function(Rect) onCropAreaChanged;

  const ImageCropWidget({
    super.key,
    required this.imagePath,
    required this.initialCropArea,
    required this.onCropAreaChanged,
  });

  @override
  State<ImageCropWidget> createState() => _ImageCropWidgetState();
}

class _ImageCropWidgetState extends State<ImageCropWidget> {
  late Rect _cropArea;
  Size _imageSize = Size.zero;
  Size _displaySize = Size.zero;
  double _imageScale = 1.0;

  @override
  void initState() {
    super.initState();
    _cropArea = widget.initialCropArea;
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    final image = Image.file(File(widget.imagePath));
    final completer = image.image.resolve(const ImageConfiguration());
    completer.addListener(ImageStreamListener((info, _) {
      setState(() {
        _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _calculateDisplaySize(constraints);
        
        if (_cropArea == Rect.zero && _displaySize != Size.zero) {
          // Set initial crop area to center 80% of the image
          final margin = 0.1;
          _cropArea = Rect.fromLTWH(
            _displaySize.width * margin,
            _displaySize.height * margin,
            _displaySize.width * (1 - 2 * margin),
            _displaySize.height * (1 - 2 * margin),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCropAreaChanged(_cropArea);
          });
        }

        return Center(
          child: Container(
            width: _displaySize.width,
            height: _displaySize.height,
            child: Stack(
              children: [
                // Background image
                Image.file(
                  File(widget.imagePath),
                  width: _displaySize.width,
                  height: _displaySize.height,
                  fit: BoxFit.contain,
                ),

                // Semi-transparent overlay
                if (_cropArea != Rect.zero)
                  CustomPaint(
                    size: _displaySize,
                    painter: CropOverlayPainter(
                      cropArea: _cropArea,
                      displaySize: _displaySize,
                    ),
                  ),

                // Crop area handles
                if (_cropArea != Rect.zero) ...[
                  // Top-left handle
                  _buildHandle(
                    left: _cropArea.left - 12,
                    top: _cropArea.top - 12,
                    onPanUpdate: (details) {
                      _updateCropArea(
                        left: _cropArea.left + details.delta.dx,
                        top: _cropArea.top + details.delta.dy,
                      );
                    },
                  ),

                  // Top-right handle
                  _buildHandle(
                    left: _cropArea.right - 12,
                    top: _cropArea.top - 12,
                    onPanUpdate: (details) {
                      _updateCropArea(
                        right: _cropArea.right + details.delta.dx,
                        top: _cropArea.top + details.delta.dy,
                      );
                    },
                  ),

                  // Bottom-left handle
                  _buildHandle(
                    left: _cropArea.left - 12,
                    top: _cropArea.bottom - 12,
                    onPanUpdate: (details) {
                      _updateCropArea(
                        left: _cropArea.left + details.delta.dx,
                        bottom: _cropArea.bottom + details.delta.dy,
                      );
                    },
                  ),

                  // Bottom-right handle
                  _buildHandle(
                    left: _cropArea.right - 12,
                    top: _cropArea.bottom - 12,
                    onPanUpdate: (details) {
                      _updateCropArea(
                        right: _cropArea.right + details.delta.dx,
                        bottom: _cropArea.bottom + details.delta.dy,
                      );
                    },
                  ),

                  // Center drag handle for moving the entire crop area
                  Positioned(
                    left: _cropArea.left,
                    top: _cropArea.top,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        _moveCropArea(details.delta);
                      },
                      child: Container(
                        width: _cropArea.width,
                        height: _cropArea.height,
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.open_with,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Drag to move',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle({
    required double left,
    required double top,
    required Function(DragUpdateDetails) onPanUpdate,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.drag_indicator,
            color: Colors.white,
            size: 12,
          ),
        ),
      ),
    );
  }

  void _calculateDisplaySize(BoxConstraints constraints) {
    if (_imageSize == Size.zero) return;

    final aspectRatio = _imageSize.width / _imageSize.height;
    final containerAspectRatio = constraints.maxWidth / constraints.maxHeight;

    if (aspectRatio > containerAspectRatio) {
      // Image is wider than container
      _displaySize = Size(
        constraints.maxWidth,
        constraints.maxWidth / aspectRatio,
      );
    } else {
      // Image is taller than container
      _displaySize = Size(
        constraints.maxHeight * aspectRatio,
        constraints.maxHeight,
      );
    }

    _imageScale = _displaySize.width / _imageSize.width;
  }

  void _updateCropArea({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    setState(() {
      final newLeft = left ?? _cropArea.left;
      final newTop = top ?? _cropArea.top;
      final newRight = right ?? _cropArea.right;
      final newBottom = bottom ?? _cropArea.bottom;

      // Ensure minimum crop area size
      const minSize = 50.0;
      
      // Clamp values to image bounds
      final clampedLeft = (newLeft).clamp(0.0, _displaySize.width - minSize);
      final clampedTop = (newTop).clamp(0.0, _displaySize.height - minSize);
      final clampedRight = (newRight).clamp(clampedLeft + minSize, _displaySize.width);
      final clampedBottom = (newBottom).clamp(clampedTop + minSize, _displaySize.height);

      _cropArea = Rect.fromLTRB(
        clampedLeft,
        clampedTop,
        clampedRight,
        clampedBottom,
      );

      widget.onCropAreaChanged(_cropArea);
    });
  }

  void _moveCropArea(Offset delta) {
    setState(() {
      final newLeft = _cropArea.left + delta.dx;
      final newTop = _cropArea.top + delta.dy;
      
      // Ensure the crop area stays within bounds
      final clampedLeft = newLeft.clamp(0.0, _displaySize.width - _cropArea.width);
      final clampedTop = newTop.clamp(0.0, _displaySize.height - _cropArea.height);
      
      _cropArea = Rect.fromLTWH(
        clampedLeft,
        clampedTop,
        _cropArea.width,
        _cropArea.height,
      );

      widget.onCropAreaChanged(_cropArea);
    });
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect cropArea;
  final Size displaySize;

  CropOverlayPainter({
    required this.cropArea,
    required this.displaySize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final cropBorderPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final gridPaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw overlay (everything except crop area)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, displaySize.width, displaySize.height))
      ..addRect(cropArea)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Draw crop area border
    canvas.drawRect(cropArea, cropBorderPaint);

    // Draw grid lines (rule of thirds)
    final thirdWidth = cropArea.width / 3;
    final thirdHeight = cropArea.height / 3;

    // Vertical grid lines
    canvas.drawLine(
      Offset(cropArea.left + thirdWidth, cropArea.top),
      Offset(cropArea.left + thirdWidth, cropArea.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropArea.left + 2 * thirdWidth, cropArea.top),
      Offset(cropArea.left + 2 * thirdWidth, cropArea.bottom),
      gridPaint,
    );

    // Horizontal grid lines
    canvas.drawLine(
      Offset(cropArea.left, cropArea.top + thirdHeight),
      Offset(cropArea.right, cropArea.top + thirdHeight),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropArea.left, cropArea.top + 2 * thirdHeight),
      Offset(cropArea.right, cropArea.top + 2 * thirdHeight),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 