import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/item.dart';
import '../utils/emoji_utils.dart';

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Extract text from image file
  static Future<String?> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (kDebugMode) {
        print('OCR Raw Text:\n${recognizedText.text}');
      }

      return recognizedText.text;
    } catch (e) {
      if (kDebugMode) {
        print('OCR Error: $e');
      }
      return null;
    }
  }

  /// Parse items from OCR text
  static List<Item> parseItemsFromText(String text) {
    final items = <Item>[];
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (kDebugMode) {
      print('Processing ${lines.length} lines from OCR');
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final item = _parseLineAsItem(line);

      if (item != null) {
        items.add(item);
        if (kDebugMode) {
          print('Parsed item: ${item.name} - ${item.price}');
        }
      }
    }

    if (kDebugMode) {
      print('Total parsed items: ${items.length}');
    }

    return items;
  }

  /// Parse a single line as an item
  static Item? _parseLineAsItem(String line) {
    try {
      // Clean the line
      final cleanLine = _cleanLine(line);

      // Skip lines that are too short or clearly not items
      if (cleanLine.length < 3) return null;
      if (_isNonItemLine(cleanLine)) return null;

      // Try different patterns to extract name and price
      final patterns = [
        // Pattern 1: "Item Name 12.50" or "Item Name ฿12.50"
        RegExp(r'^(.+?)\s+(?:฿)?(\d+(?:\.\d{1,2})?)$'),

        // Pattern 2: "Item Name     12.50" (multiple spaces)
        RegExp(r'^(.+?)\s{2,}(?:฿)?(\d+(?:\.\d{1,2})?)$'),

        // Pattern 3: "Item Name x1 12.50" or "Item Name 1x 12.50"
        RegExp(r'^(.+?)\s*(?:x?\d+|ชิ้น|\d+x?)\s*(?:฿)?(\d+(?:\.\d{1,2})?)$'),

        // Pattern 4: "12.50 Item Name" (price first)
        RegExp(r'^(?:฿)?(\d+(?:\.\d{1,2})?)\s+(.+?)$'),

        // Pattern 5: "Item Name - 12.50" or "Item Name : 12.50"
        RegExp(r'^(.+?)\s*[-:]\s*(?:฿)?(\d+(?:\.\d{1,2})?)$'),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(cleanLine);
        if (match != null) {
          String name;
          double price;

          if (patterns.indexOf(pattern) == 3) {
            // Pattern 4: price first
            price = double.parse(match.group(1)!);
            name = match.group(2)!.trim();
          } else {
            // Other patterns: name first
            name = match.group(1)!.trim();
            price = double.parse(match.group(2)!);
          }

          // Validate extracted data
          if (name.isEmpty || price <= 0 || price > 99999) continue;

          // Clean the name
          name = _cleanItemName(name);
          if (name.isEmpty || name.length < 2) continue;

          // Generate unique ID and emoji
          final id =
              '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
          final emoji = EmojiUtils.generateEmoji(name);

          return Item(
            id: id,
            name: name,
            price: price,
            emoji: emoji,
            ownerIds: [], // Will be set later when user selects owners
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing line "$line": $e');
      }
    }

    return null;
  }

  /// Clean a line for better parsing
  static String _cleanLine(String line) {
    return line
        .replaceAll(
          RegExp(r'[^\w\s\d\.\-:฿]'),
          '',
        ) // Remove special chars except common ones
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Check if a line should be skipped (not an item)
  static bool _isNonItemLine(String line) {
    final lowerLine = line.toLowerCase();

    // Skip common receipt headers/footers
    final skipPatterns = [
      'receipt',
      'total',
      'subtotal',
      'tax',
      'vat',
      'discount',
      'change',
      'cash',
      'card',
      'credit',
      'thank',
      'welcome',
      'address',
      'phone',
      'date',
      'time',
      'store',
      'shop',
      'company',
      'ltd',
      'co',
      'ใบเสร็จ',
      'รวม',
      'ยอดรวม',
      'ภาษี',
      'ส่วนลด',
      'เงินทอน',
      'เงินสด',
      'บัตร',
      'ขอบคุณ',
      'ยินดีต้อนรับ',
      'ที่อยู่',
      'เบอร์',
      'วันที่',
      'เวลา',
      'ร้าน',
      'บริษัท',
    ];

    for (final pattern in skipPatterns) {
      if (lowerLine.contains(pattern)) return true;
    }

    // Skip lines that are only numbers or only letters
    if (RegExp(r'^\d+$').hasMatch(line)) return true;
    if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(line) && line.length < 4) return true;

    // Skip lines that look like timestamps or IDs
    if (RegExp(r'\d{2}:\d{2}').hasMatch(line)) return true;
    if (RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(line)) return true;

    return false;
  }

  /// Clean item name
  static String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'^\d+[\.\-\s]*'), '') // Remove leading numbers
        .replaceAll(RegExp(r'[x\*]\s*\d+$'), '') // Remove trailing quantity
        .replaceAll(RegExp(r'\s*[\-\:]\s*$'), '') // Remove trailing separators
        .trim();
  }

  /// Validate OCR results and provide suggestions
  static Map<String, dynamic> validateOCRResults(List<Item> items) {
    final issues = <String>[];
    final suggestions = <String>[];

    if (items.isEmpty) {
      issues.add('ไม่พบรายการใดจากการสแกน');
      suggestions.add('ลองครอบรูปให้แค่บริเวณรายการอาหาร');
      suggestions.add('ตรวจสอบว่าแสงเพียงพอและข้อความชัดเจน');
    } else {
      // Check for unusually high prices
      final highPriceItems = items.where((item) => item.price > 1000).toList();
      if (highPriceItems.isNotEmpty) {
        issues.add('มีรายการราคาสูงผิดปกติ');
        suggestions.add('กรุณาตรวจสอบราคาของรายการที่สแกนได้');
      }

      // Check for very short names
      final shortNameItems = items
          .where((item) => item.name.length < 3)
          .toList();
      if (shortNameItems.isNotEmpty) {
        issues.add('มีรายการที่ชื่อสั้นเกินไป');
        suggestions.add('อาจต้องแก้ไขชื่อรายการให้ชัดเจนขึ้น');
      }

      // Check for duplicate names
      final nameGroups = <String, int>{};
      for (final item in items) {
        nameGroups[item.name] = (nameGroups[item.name] ?? 0) + 1;
      }
      final duplicates = nameGroups.entries.where((e) => e.value > 1).toList();
      if (duplicates.isNotEmpty) {
        issues.add('มีรายการที่ชื่อซ้ำกัน');
        suggestions.add('ตรวจสอบและรวมรายการที่ซ้ำกัน');
      }
    }

    return {
      'items': items,
      'issues': issues,
      'suggestions': suggestions,
      'confidence': _calculateConfidence(items),
    };
  }

  /// Calculate confidence score for OCR results
  static double _calculateConfidence(List<Item> items) {
    if (items.isEmpty) return 0.0;

    double score = 0.5; // Base score

    // Add points for reasonable number of items
    if (items.length >= 2 && items.length <= 20) {
      score += 0.2;
    }

    // Add points for reasonable prices
    final reasonablePrices = items
        .where((item) => item.price >= 1.0 && item.price <= 500.0)
        .length;
    score += (reasonablePrices / items.length) * 0.2;

    // Add points for reasonable name lengths
    final reasonableNames = items
        .where((item) => item.name.length >= 3 && item.name.length <= 30)
        .length;
    score += (reasonableNames / items.length) * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Dispose resources
  static void dispose() {
    _textRecognizer.close();
  }
}
