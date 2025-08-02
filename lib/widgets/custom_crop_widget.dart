import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';

import '../utils/constants.dart';

class CustomCropWidget extends StatefulWidget {
  final File imageFile;
  final String title;

  const CustomCropWidget({
    super.key,
    required this.imageFile,
    this.title = 'ครอบรูปใบเสร็จ',
  });

  @override
  State<CustomCropWidget> createState() => _CustomCropWidgetState();
}

class _CustomCropWidgetState extends State<CustomCropWidget> {
  ui.Image? _image;
  bool _isImageLoaded = false;
  Rect? _cropRect;
  Offset? _startPoint;
  Offset? _endPoint;
  bool _isDrawing = false;
  Size _imageDisplaySize = Size.zero;
  Offset _imageOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _isImageLoaded = true;
    });
  }

  void _onPanStart(DragStartDetails details) {
    final clampedStart = _clampToImageBounds(details.localPosition);
    setState(() {
      _startPoint = clampedStart;
      _isDrawing = true;
      _cropRect = Rect
          .zero; // This will hide the tip immediately when user starts drawing
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_startPoint != null) {
      final clampedEnd = _clampToImageBounds(details.localPosition);
      setState(() {
        _endPoint = clampedEnd;
        _cropRect = Rect.fromPoints(_startPoint!, _endPoint!);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDrawing = false;
    });
  }

  void _resetCrop() {
    setState(() {
      _cropRect = null;
      _startPoint = null;
      _endPoint = null;
      _isDrawing = false;
    });
  }

  /// Clamp touch position to image bounds
  Offset _clampToImageBounds(Offset position) {
    if (_imageDisplaySize == Size.zero || _imageOffset == Offset.zero) {
      return position;
    }

    final imageRect = Rect.fromLTWH(
      _imageOffset.dx,
      _imageOffset.dy,
      _imageDisplaySize.width,
      _imageDisplaySize.height,
    );

    return Offset(
      position.dx.clamp(imageRect.left, imageRect.right),
      position.dy.clamp(imageRect.top, imageRect.bottom),
    );
  }

  Future<File?> _cropAndSave() async {
    if (_cropRect == null || _image == null) return null;

    try {
      // Calculate the scale factors
      final imageSize = Size(
        _image!.width.toDouble(),
        _image!.height.toDouble(),
      );
      final scaleX = imageSize.width / _imageDisplaySize.width;
      final scaleY = imageSize.height / _imageDisplaySize.height;

      // Convert display coordinates to image coordinates
      final adjustedCropRect = Rect.fromLTWH(
        (_cropRect!.left - _imageOffset.dx) * scaleX,
        (_cropRect!.top - _imageOffset.dy) * scaleY,
        _cropRect!.width * scaleX,
        _cropRect!.height * scaleY,
      );

      // Ensure crop rect is within image bounds
      final clampedRect = Rect.fromLTWH(
        adjustedCropRect.left.clamp(0.0, imageSize.width),
        adjustedCropRect.top.clamp(0.0, imageSize.height),
        adjustedCropRect.width.clamp(
          0.0,
          imageSize.width - adjustedCropRect.left,
        ),
        adjustedCropRect.height.clamp(
          0.0,
          imageSize.height - adjustedCropRect.top,
        ),
      );

      // Create cropped image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawImageRect(
        _image!,
        clampedRect,
        Rect.fromLTWH(0, 0, clampedRect.width, clampedRect.height),
        Paint(),
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        clampedRect.width.toInt(),
        clampedRect.height.toInt(),
      );

      // Convert to bytes and save
      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final bytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final croppedFile = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await croppedFile.writeAsBytes(bytes);

      return croppedFile;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_cropRect != null)
            IconButton(
              onPressed: _resetCrop,
              icon: const Icon(Icons.refresh),
              tooltip: 'เริ่มใหม่',
            ),
          TextButton(
            onPressed: _cropRect != null
                ? () async {
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );

                    final croppedFile = await _cropAndSave();

                    if (context.mounted) {
                      Navigator.of(context).pop(); // Close loading
                      Navigator.of(context).pop(croppedFile); // Return result
                    }
                  }
                : null,
            child: Text(
              'เสร็จ',
              style: TextStyle(
                color: _cropRect != null ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isImageLoaded
          ? Column(
              children: [
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  child: Column(
                    children: [
                      const Text(
                        '✨ วาดกรอบรอบส่วนที่ต้องการ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            color: Colors.white70,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ลากนิ้วจากมุมหนึ่งไปอีกมุมหนึ่งเพื่อวาดกรอบ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.crop, color: Colors.white70, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'เลือกเฉพาะส่วนใบเสร็จ หลีกเลี่ยงพื้นหลัง',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.white70, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'กดรีเฟรชเพื่อเริ่มวาดใหม่',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Image with crop overlay
                Expanded(
                  child: Stack(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (_image == null) return const SizedBox();

                          // Calculate image display size and position
                          final imageAspectRatio =
                              _image!.width / _image!.height;
                          final containerAspectRatio =
                              constraints.maxWidth / constraints.maxHeight;

                          if (imageAspectRatio > containerAspectRatio) {
                            // Image is wider than container
                            _imageDisplaySize = Size(
                              constraints.maxWidth,
                              constraints.maxWidth / imageAspectRatio,
                            );
                          } else {
                            // Image is taller than container
                            _imageDisplaySize = Size(
                              constraints.maxHeight * imageAspectRatio,
                              constraints.maxHeight,
                            );
                          }

                          _imageOffset = Offset(
                            (constraints.maxWidth - _imageDisplaySize.width) /
                                2,
                            (constraints.maxHeight - _imageDisplaySize.height) /
                                2,
                          );

                          return GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: Container(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              color: Colors.black,
                              child: CustomPaint(
                                painter: CropPainter(
                                  image: _image!,
                                  imageDisplaySize: _imageDisplaySize,
                                  imageOffset: _imageOffset,
                                  cropRect: _cropRect,
                                  isDrawing: _isDrawing,
                                ),
                                size: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Floating tip when no crop area is drawn - non-interactive
                      if (_cropRect == null)
                        Positioned(
                          top: 20,
                          left: 20,
                          right: 20,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'เริ่มต้นด้วยการลากนิ้วบนรูปภาพเพื่อวาดกรอบ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class CropPainter extends CustomPainter {
  final ui.Image image;
  final Size imageDisplaySize;
  final Offset imageOffset;
  final Rect? cropRect;
  final bool isDrawing;

  CropPainter({
    required this.image,
    required this.imageDisplaySize,
    required this.imageOffset,
    this.cropRect,
    this.isDrawing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image
    final imageRect = Rect.fromLTWH(
      imageOffset.dx,
      imageOffset.dy,
      imageDisplaySize.width,
      imageDisplaySize.height,
    );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint(),
    );

    // Draw crop area with transparent background (only show border)
    if (cropRect != null) {
      // Draw crop border
      final borderPaint = Paint()
        ..color = AppConstants.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(cropRect!, borderPaint);

      // Draw corner handles
      final handlePaint = Paint()
        ..color = AppConstants.primaryColor
        ..style = PaintingStyle.fill;

      const handleSize = 8.0;
      final handles = [
        // Top-left
        Rect.fromCenter(
          center: cropRect!.topLeft,
          width: handleSize,
          height: handleSize,
        ),
        // Top-right
        Rect.fromCenter(
          center: cropRect!.topRight,
          width: handleSize,
          height: handleSize,
        ),
        // Bottom-left
        Rect.fromCenter(
          center: cropRect!.bottomLeft,
          width: handleSize,
          height: handleSize,
        ),
        // Bottom-right
        Rect.fromCenter(
          center: cropRect!.bottomRight,
          width: handleSize,
          height: handleSize,
        ),
      ];

      for (final handle in handles) {
        canvas.drawRect(handle, handlePaint);
      }

      // Draw grid lines
      final gridPaint = Paint()
        ..color = AppConstants.primaryColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Vertical lines
      final thirdWidth = cropRect!.width / 3;
      canvas.drawLine(
        Offset(cropRect!.left + thirdWidth, cropRect!.top),
        Offset(cropRect!.left + thirdWidth, cropRect!.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect!.left + 2 * thirdWidth, cropRect!.top),
        Offset(cropRect!.left + 2 * thirdWidth, cropRect!.bottom),
        gridPaint,
      );

      // Horizontal lines
      final thirdHeight = cropRect!.height / 3;
      canvas.drawLine(
        Offset(cropRect!.left, cropRect!.top + thirdHeight),
        Offset(cropRect!.right, cropRect!.top + thirdHeight),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect!.left, cropRect!.top + 2 * thirdHeight),
        Offset(cropRect!.right, cropRect!.top + 2 * thirdHeight),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CropPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
        oldDelegate.isDrawing != isDrawing;
  }
}
