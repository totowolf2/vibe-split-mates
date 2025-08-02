import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class ExportService {
  /// Export widget as PNG image to gallery
  static Future<bool> exportWidgetAsImage({
    required GlobalKey repaintBoundaryKey,
    String? filename,
    double pixelRatio = 2.0,
  }) async {
    try {
      // Check and request permissions
      if (!await _checkPermissions()) {
        if (kDebugMode) {
          print('Storage permission denied');
        }
        return false;
      }

      // Get the RenderRepaintBoundary
      final RenderRepaintBoundary? boundary =
          repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        if (kDebugMode) {
          print('Could not find RenderRepaintBoundary');
        }
        return false;
      }

      // Capture the widget as image
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        if (kDebugMode) {
          print('Could not convert image to bytes');
        }
        return false;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Generate filename if not provided
      final String fileName =
          filename ?? 'splitmates_${DateTime.now().millisecondsSinceEpoch}.png';

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        name: fileName,
        isReturnImagePathOfIOS: true,
      );

      // Check if save was successful
      if (result != null && result['isSuccess'] == true) {
        if (kDebugMode) {
          print('Image saved successfully: ${result['filePath']}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to save image: $result');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting image: $e');
      }
      return false;
    }
  }

  /// Check and request necessary permissions
  static Future<bool> _checkPermissions() async {
    try {
      // Check current permission status
      PermissionStatus permission = await Permission.storage.status;

      // For Android 13+, we need different permissions
      if (await Permission.photos.isDenied) {
        permission = await Permission.photos.status;
      }

      if (permission.isDenied) {
        // Request permission
        final Map<Permission, PermissionStatus> permissions = await [
          Permission.storage,
          Permission.photos,
        ].request();

        // Check if any permission was granted
        return permissions.values.any(
          (status) =>
              status == PermissionStatus.granted ||
              status == PermissionStatus.limited,
        );
      }

      return permission == PermissionStatus.granted ||
          permission == PermissionStatus.limited;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permissions: $e');
      }
      return false;
    }
  }

  /// Get permission status message for UI
  static Future<String> getPermissionStatusMessage() async {
    try {
      final storageStatus = await Permission.storage.status;
      final photosStatus = await Permission.photos.status;

      if (storageStatus.isGranted || photosStatus.isGranted) {
        return 'สามารถบันทึกรูปภาพได้';
      } else if (storageStatus.isDenied || photosStatus.isDenied) {
        return 'ต้องการอนุญาตเข้าถึงที่เก็บข้อมูล';
      } else if (storageStatus.isPermanentlyDenied ||
          photosStatus.isPermanentlyDenied) {
        return 'กรุณาเปิดอนุญาตในการตั้งค่า';
      } else {
        return 'ตรวจสอบสิทธิ์การเข้าถึง';
      }
    } catch (e) {
      return 'ไม่สามารถตรวจสอบสิทธิ์ได้';
    }
  }

  /// Open app settings for permission management
  static Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        print('Error opening app settings: $e');
      }
      return false;
    }
  }

  /// Check if device supports image saving
  static bool get isSupported {
    // Image gallery saver supports iOS and Android
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  /// Generate a filename for the export
  static String generateFileName({String prefix = 'splitmates'}) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '${prefix}_$timestamp.png';
  }

  /// Calculate optimal pixel ratio based on device
  static double getOptimalPixelRatio(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Limit pixel ratio to prevent memory issues
    if (devicePixelRatio > 3.0) {
      return 3.0;
    } else if (devicePixelRatio < 1.0) {
      return 2.0;
    }

    return devicePixelRatio;
  }

  /// Estimate image size in MB
  static double estimateImageSize({
    required double width,
    required double height,
    double pixelRatio = 2.0,
  }) {
    final totalPixels = width * height * pixelRatio * pixelRatio;
    // PNG typically uses 4 bytes per pixel (RGBA)
    final bytes = totalPixels * 4;
    return bytes / (1024 * 1024); // Convert to MB
  }

  /// Validate widget is ready for export
  static bool validateForExport(GlobalKey repaintBoundaryKey) {
    try {
      final context = repaintBoundaryKey.currentContext;
      if (context == null) return false;

      final renderObject = context.findRenderObject();
      if (renderObject == null) return false;

      return renderObject is RenderRepaintBoundary &&
          renderObject.debugNeedsPaint == false;
    } catch (e) {
      return false;
    }
  }
}
