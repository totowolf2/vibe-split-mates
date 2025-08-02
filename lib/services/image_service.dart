import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_crop_widget.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/constants.dart';

class ImageService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from gallery or camera
  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Check permissions
      if (!await _checkPermissions(source)) {
        if (kDebugMode) {
          print('Permission denied for image source: $source');
        }
        return null;
      }

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        if (kDebugMode) {
          print('No image picked');
        }
        return null;
      }

      if (kDebugMode) {
        print('Image picked: ${pickedFile.path}');
      }

      return File(pickedFile.path);
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      return null;
    }
  }

  /// Crop image for better OCR results using custom crop widget
  static Future<File?> cropImage(File imageFile, BuildContext context) async {
    try {
      final croppedFile = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (context) => CustomCropWidget(
            imageFile: imageFile,
            title: 'ครอบรูปใบเสร็จ - วาดกรอบรอบส่วนที่ต้องการ',
          ),
        ),
      );

      if (croppedFile == null) {
        if (kDebugMode) {
          print('Image cropping cancelled');
        }
        return null;
      }

      if (kDebugMode) {
        print('Image cropped: ${croppedFile.path}');
      }

      return croppedFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error cropping image: $e');
      }
      return null;
    }
  }

  /// Pick and crop image in one flow
  static Future<File?> pickAndCropImage({
    ImageSource source = ImageSource.gallery,
    required BuildContext context,
  }) async {
    try {
      // Pick image
      final pickedImage = await pickImage(source: source);
      if (pickedImage == null) return null;

      // Check if context is still mounted before using it
      if (!context.mounted) return null;

      // Crop image
      final croppedImage = await cropImage(pickedImage, context);

      // Clean up original picked image if different from cropped
      if (croppedImage != null && croppedImage.path != pickedImage.path) {
        try {
          await pickedImage.delete();
        } catch (e) {
          if (kDebugMode) {
            print('Could not delete original image: $e');
          }
        }
      }

      return croppedImage;
    } catch (e) {
      if (kDebugMode) {
        print('Error in pick and crop flow: $e');
      }
      return null;
    }
  }

  /// Check permissions for image source
  static Future<bool> _checkPermissions(ImageSource source) async {
    try {
      PermissionStatus permission;

      if (source == ImageSource.camera) {
        permission = await Permission.camera.status;
        if (permission.isDenied) {
          permission = await Permission.camera.request();
        }
      } else {
        // For gallery access
        permission = await Permission.photos.status;
        if (permission.isDenied) {
          permission = await Permission.photos.request();
        }

        // Fallback to storage permission for older Android versions
        if (permission.isDenied) {
          permission = await Permission.storage.status;
          if (permission.isDenied) {
            permission = await Permission.storage.request();
          }
        }
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

  /// Get permission status message
  static Future<String> getPermissionStatusMessage(ImageSource source) async {
    try {
      final permission = source == ImageSource.camera
          ? await Permission.camera.status
          : await Permission.photos.status;

      switch (permission) {
        case PermissionStatus.granted:
        case PermissionStatus.limited:
          return 'มีสิทธิ์เข้าถึง';
        case PermissionStatus.denied:
          return source == ImageSource.camera
              ? 'ต้องการอนุญาตใช้กล้อง'
              : 'ต้องการอนุญาตเข้าถึงรูปภาพ';
        case PermissionStatus.permanentlyDenied:
          return 'กรุณาเปิดอนุญาตในการตั้งค่า';
        default:
          return 'ตรวจสอบสิทธิ์การเข้าถึง';
      }
    } catch (e) {
      return 'ไม่สามารถตรวจสอบสิทธิ์ได้';
    }
  }

  /// Validate image file
  static bool validateImageFile(File imageFile) {
    try {
      // Check if file exists
      if (!imageFile.existsSync()) {
        if (kDebugMode) {
          print('Image file does not exist');
        }
        return false;
      }

      // Check file size (limit to 10MB)
      final fileSize = imageFile.lengthSync();
      if (fileSize > 10 * 1024 * 1024) {
        if (kDebugMode) {
          print('Image file too large: ${fileSize / (1024 * 1024)} MB');
        }
        return false;
      }

      // Check file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (!AppConstants.supportedImageFormats.contains(extension)) {
        if (kDebugMode) {
          print('Unsupported image format: $extension');
        }
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating image file: $e');
      }
      return false;
    }
  }

  /// Get file size in human readable format
  static String getFileSizeString(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Clean up temporary image files
  static Future<void> cleanupTempFiles(List<String> filePaths) async {
    for (final path in filePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          if (kDebugMode) {
            print('Cleaned up temp file: $path');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Could not clean up file $path: $e');
        }
      }
    }
  }

  /// Show image source selection dialog
  static Future<ImageSource?> showImageSourceDialog(
    BuildContext context,
  ) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกแหล่งรูปภาพ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากแกลเลอรี่'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่าย photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }
}
