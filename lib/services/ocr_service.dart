import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/item.dart';
import '../utils/emoji_utils.dart';

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from image file with enhanced Thai language support
  static Future<String?> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (kDebugMode) {
        print('OCR Raw Text:\n${recognizedText.text}');
      }

      // Return raw text for better parsing, enhancement will be done during parsing if needed
      return recognizedText.text;
    } catch (e) {
      if (kDebugMode) {
        print('OCR Error: $e');
      }
      return null;
    }
  }

  /// Parse items from OCR text with improved Thai receipt format handling
  static List<Item> parseItemsFromText(String text) {
    final items = <Item>[];

    // Use raw text first to get better parsing results
    final rawLines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (kDebugMode) {
      print('Processing ${rawLines.length} lines from OCR');
    }

    // Try structured receipt format first (like Walmart receipts)
    var reconstructedItems = _parseStructuredReceipt(rawLines);
    
    // If no structured items found, use regular parsing
    if (reconstructedItems.isEmpty) {
      reconstructedItems = _reconstructReceiptItems(rawLines);
    }

    for (int i = 0; i < reconstructedItems.length; i++) {
      final itemData = reconstructedItems[i];
      final item = _parseReconstructedItem(itemData, i);
      if (item != null) {
        items.add(item);
        if (kDebugMode) {
          print('Parsed item: ${item.name} - ${item.price}');
        }
      }
    }

    // Fallback to old method if new method fails
    if (items.isEmpty) {
      items.addAll(_parseItemsWithSeparateLines(rawLines));
    }

    if (kDebugMode) {
      print('Total parsed items: ${items.length}');
    }

    return items;
  }

  /// Parse structured receipt format (like Walmart receipts)
  static List<Map<String, dynamic>> _parseStructuredReceipt(
    List<String> lines,
  ) {
    final items = <Map<String, dynamic>>[];
    final itemNames = <String>[];
    final itemPrices = <double>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Skip header/footer lines
      if (_isNonItemLine(trimmedLine)) continue;
      
      // Check if line is a price (multiple formats)
      RegExpMatch? priceMatch;
      
      // Format 1: "1.97 X" (Walmart style) 
      priceMatch = RegExp(r'^(\d+\.\d{2})\s*[XONF-]').firstMatch(trimmedLine);
      
      // Format 2: "$ 35.00" or "$35.00"
      priceMatch ??= RegExp(r'^\$\s*(\d+\.\d{2})$').firstMatch(trimmedLine);
      
      // Format 3: Just numbers "35.00"  
      priceMatch ??= RegExp(r'^(\d+\.\d{2})$').firstMatch(trimmedLine);
      
      if (priceMatch != null) {
        final price = double.tryParse(priceMatch.group(1)!);
        if (price != null && price > 0) {
          itemPrices.add(price);
          continue;
        }
      }
      
      // Check if line looks like an item name 
      if ((RegExp(r'^[A-Z][A-Z\s\d\.]+$').hasMatch(trimmedLine) || 
           RegExp(r'^\d+[xX]\s+[A-Za-z\s]+$').hasMatch(trimmedLine)) && 
          !RegExp(r'^\d+$').hasMatch(trimmedLine) &&
          !RegExp(r'^\$').hasMatch(trimmedLine) &&
          trimmedLine.length >= 3 &&
          trimmedLine.length <= 50) {
        
        // Clean the name - remove quantity prefix and barcodes
        String cleanName = trimmedLine
            .replaceAll(RegExp(r'^\d+[xX]\s+'), '') // Remove "1x ", "2X " etc
            .replaceAll(RegExp(r'\s+\d{10,}'), '') // Remove barcodes
            .trim();
        if (cleanName.length >= 3) {
          itemNames.add(cleanName);
        }
      }
    }

    if (kDebugMode) {
      print('Found item names: $itemNames');
      print('Found item prices: $itemPrices');
    }

    // Match names with prices (use all available names, even if more prices exist)
    final itemCount = itemNames.length;
    
    for (int i = 0; i < itemCount; i++) {
      String name = itemNames[i];
      
      // Truncate long names
      if (name.length > 20) {
        name = '${name.substring(0, 17)}...';
      }
      
      // Only add if we have a corresponding price
      if (i < itemPrices.length) {
        items.add({
          'quantity': 1,
          'name': name,
          'price': itemPrices[i],
        });
      }

      if (kDebugMode && i < itemPrices.length) {
        print('Structured receipt item: $name - ${itemPrices[i]}');
      }
    }

    return items;
  }

  /// Reconstruct receipt items from scattered OCR lines
  static List<Map<String, dynamic>> _reconstructReceiptItems(
    List<String> lines,
  ) {
    final items = <Map<String, dynamic>>[];

    // Separate quantities, names, and prices
    final quantities = <int>[];
    final possibleNames = <String>[];
    final prices = <double>[];

    for (final line in lines) {
      // Check if line is a standalone quantity (1, 2, 3, etc.)
      if (RegExp(r'^\d+$').hasMatch(line)) {
        final qty = int.tryParse(line);
        if (qty != null && qty > 0 && qty <= 99) {
          quantities.add(qty);
          continue;
        }
      }

      // Check if line is a price (ends with .00 or similar)
      final priceMatch = RegExp(r'^(\d+(?:\.\d{2})?)$').firstMatch(line);
      if (priceMatch != null) {
        final price = double.tryParse(priceMatch.group(1)!);
        if (price != null && price > 0 && price <= 9999) {
          // Allow all positive prices including small amounts like 0.40
          prices.add(price);
          continue;
        }
      }

      // Otherwise, consider it a potential product name
      if (line.length > 1 && !_isNonItemLine(line)) {
        possibleNames.add(line);
      }
    }

    if (kDebugMode) {
      print('Found quantities: $quantities');
      print('Found names: $possibleNames');
      print('Found prices: $prices');
    }

    // Match quantities, names, and prices
    final maxItems = [
      quantities.length,
      possibleNames.length,
      prices.length,
    ].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxItems; i++) {
      final quantity = i < quantities.length ? quantities[i] : 1;
      final name = i < possibleNames.length ? possibleNames[i] : 'รายการสินค้า';
      final price = i < prices.length ? prices[i] : 0.0;

      if (price > 0) {
        items.add({'quantity': quantity, 'name': name, 'price': price});
      }
    }

    return items;
  }

  /// Parse a reconstructed item data
  static Item? _parseReconstructedItem(
    Map<String, dynamic> itemData, [
    int? index,
  ]) {
    try {
      String name = itemData['name'] as String;
      final price = itemData['price'] as double;

      // Clean the name
      name = _cleanItemName(name);
      if (name.isEmpty) name = 'รายการสินค้า';

      // Check if name contains readable English text, if not use generic name
      if (!_isReadableEnglishText(name)) {
        if (kDebugMode) {
          print('Replacing unreadable name "$name" with รายการสินค้า');
        }
        name = 'รายการสินค้า';
      } else {
        if (kDebugMode) {
          print('Keeping readable name: "$name"');
        }
      }

      // Generate unique ID and emoji
      final id =
          '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
      // Force random emoji for generic names like "รายการสินค้า"
      final isGenericName =
          name == 'รายการสินค้า' ||
          name == 'สินค้า' ||
          name == 'รายการ' ||
          name == 'item';
      final emoji = EmojiUtils.generateEmoji(
        name,
        additionalSeed: index,
        forceRandom: isGenericName,
      );

      return Item(id: id, name: name, price: price, emoji: emoji, ownerIds: []);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing reconstructed item: $e');
      }
      return null;
    }
  }

  /// Check if text contains readable English words
  static bool _isReadableEnglishText(String text) {
    if (text.isEmpty || text.length < 3) return false;

    // First check for obvious non-English characters that indicate garbled OCR
    // Reject text with accented letters, special symbols, or weird Unicode characters
    if (RegExp(r'[^a-zA-Z0-9\s\-\.\,]').hasMatch(text)) {
      if (kDebugMode) {
        print('Rejecting "$text" due to non-English characters');
      }
      return false;
    }

    // Clean text for analysis
    final cleanText = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .trim();
    if (cleanText.length < 3) return false;

    if (kDebugMode) {
      print('Checking readability for: "$text" -> cleaned: "$cleanText"');
    }

    // Check if it contains mostly English letters
    final englishChars = RegExp(r'[a-z]').allMatches(cleanText).length;
    final totalChars = cleanText.replaceAll(' ', '').length;

    if (totalChars == 0) return false;
    final englishRatio = englishChars / totalChars;

    if (kDebugMode) {
      print('English ratio: $englishRatio ($englishChars/$totalChars)');
    }

    // Must be at least 70% English characters (more strict)
    if (englishRatio < 0.7) return false;

    // Simple heuristics for readable English text
    final words = cleanText.split(RegExp(r'\s+'));
    int validWords = 0;

    for (final word in words) {
      if (word.length < 2) continue;
      
      // Simple checks for English-like words
      if (_isEnglishLikeWord(word)) {
        validWords++;
        if (kDebugMode) {
          print('Found valid word: "$word"');
        }
      }
    }

    if (kDebugMode) {
      print('Valid words: $validWords');
    }

    // Accept if at least 50% of words look English-like (more strict)
    return validWords >= (words.length * 0.5).ceil();
  }

  /// Check if word looks like English
  static bool _isEnglishLikeWord(String word) {
    if (word.length < 2) return false;

    // Reject words with non-English characters (accented letters, symbols, etc.)
    if (RegExp(r'[^a-z]').hasMatch(word)) return false;
    
    // Must contain at least one vowel
    final vowelCount = RegExp(r'[aeiou]').allMatches(word).length;
    if (vowelCount == 0) return false;
    
    // Check vowel to consonant ratio (should have reasonable balance)
    final consonantCount = word.length - vowelCount;
    if (consonantCount == 0) return false; // All vowels is unlikely
    
    final vowelRatio = vowelCount / word.length;
    // English words typically have 15-70% vowels (more relaxed)
    if (vowelRatio < 0.15 || vowelRatio > 0.7) return false;
    
    // Reject obvious garbage patterns only
    // Avoid sequences of 4+ consonants or vowels (very rare in English)
    if (RegExp(r'[bcdfghjklmnpqrstvwxyz]{4,}').hasMatch(word) ||
        RegExp(r'[aeiou]{4,}').hasMatch(word)) {
      return false;
    }
    
    // Check for common English word patterns (more comprehensive)
    final commonStarts = [
      'th', 'st', 'ch', 'sh', 'wh', 'br', 'cr', 'dr', 'fr', 'gr', 'pr', 'tr', 
      'bl', 'cl', 'fl', 'gl', 'pl', 'sl', 'sc', 'sk', 'sm', 'sn', 'sp', 'sw'
    ];
    final commonEndings = [
      'ed', 'ing', 'er', 'est', 'ly', 'tion', 'ness', 'ment', 'able', 'ible',
      'ful', 'less', 'ous', 'ive', 'ate', 'ize', 'ise', 'ity', 'al', 'ic', 'en', 'an', 'or', 'ar'
    ];
    
    bool hasCommonPattern = false;
    
    // Check prefixes (if word is long enough)
    if (word.length >= 3) {
      final start = word.substring(0, 2);
      if (commonStarts.contains(start)) {
        hasCommonPattern = true;
      }
    }
    
    // Check suffixes (if word is long enough)
    if (word.length >= 3) {
      for (final ending in commonEndings) {
        if (word.endsWith(ending) && word.length > ending.length) {
          hasCommonPattern = true;
          break;
        }
      }
    }
    
    // Extended list of common English words
    final commonWords = [
      // Basic words
      'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had',
      'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his',
      'how', 'its', 'may', 'new', 'now', 'old', 'see', 'two', 'way', 'who',
      'man', 'men', 'run', 'she', 'too', 'use', 'what', 'with', 'have', 'from',
      'they', 'know', 'want', 'been', 'good', 'much', 'some', 'time', 'will',
      'come', 'each', 'first', 'than', 'them', 'well', 'when', 'where',
      // Common product/food words
      'food', 'drink', 'cake', 'bread', 'milk', 'coffee', 'tea', 'juice', 'water',
      'meat', 'fish', 'chicken', 'beef', 'rice', 'egg', 'cheese', 'pizza', 'burger',
      'apple', 'banana', 'orange', 'salad', 'sandwich', 'soup', 'pasta', 'noodle',
      // Latin words commonly used (Lorem Ipsum style)
      'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'adipiscing', 'elit', 'sed', 'tempor',
      'incididunt', 'labore', 'dolore', 'magna', 'aliqua', 'enim', 'minim', 'veniam',
      'quis', 'nostrud', 'exercitation', 'ullamco', 'laboris', 'nisi', 'aliquip',
      'commodo', 'consequat', 'duis', 'aute', 'irure', 'reprehenderit', 'voluptate',
      'velit', 'esse', 'cillum', 'fugiat', 'nulla', 'pariatur', 'excepteur', 'sint',
      'occaecat', 'cupidatat', 'proident', 'sunt', 'culpa', 'officia', 'deserunt',
      'mollit', 'anim', 'laborum'
    ];
    
    if (commonWords.contains(word)) {
      hasCommonPattern = true;
    }
    
    // For very short words (2-3 letters), be more lenient
    if (word.length <= 3) {
      return vowelRatio >= 0.25 && vowelRatio <= 0.75;
    }
    
    // For longer words, still accept if they have reasonable structure, even without common patterns
    if (vowelRatio >= 0.2 && vowelRatio <= 0.6) {
      return true; // Much more relaxed - accept most reasonable looking words
    }
    
    return hasCommonPattern;
  }

  /// Clean item name
  static String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'^\d+[\.\-\s]*'), '') // Remove leading numbers
        .replaceAll(RegExp(r'[x\*]\s*\d+$'), '') // Remove trailing quantity
        .replaceAll(
          RegExp(r'\d+\s*ชิ้น$', unicode: true),
          '',
        ) // Remove Thai quantity
        .replaceAll(RegExp(r'\s*[\-\:]\s*$'), '') // Remove trailing separators
        .replaceAll(
          RegExp(r'\s*ราคา\s*$', unicode: true),
          '',
        ) // Remove trailing "ราคา"
        .trim();
  }

  /// Try to parse items when names and prices are on separate lines
  static List<Item> _parseItemsWithSeparateLines(List<String> lines) {
    final items = <Item>[];

    // Look for patterns where price follows item name on next line
    for (int i = 0; i < lines.length - 1; i++) {
      final nameLine = lines[i];
      final priceLine = lines[i + 1];

      // Skip if name line is too short or looks like non-item
      if (nameLine.length < 3 || _isNonItemLine(nameLine)) continue;

      // Check if next line looks like a price
      final priceMatch = RegExp(
        r'^(?:฿|บาท)?(\d+(?:[,\.]\d{1,2})?)(?:\s*บาท)?$',
        unicode: true,
      ).firstMatch(priceLine.trim());

      if (priceMatch != null) {
        try {
          final price = double.parse(priceMatch.group(1)!.replaceAll(',', '.'));
          final cleanName = _cleanItemName(nameLine);

          if (cleanName.isNotEmpty &&
              cleanName.length >= 2 &&
              price > 0 &&
              price <= 99999) {
            final id =
                '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
            // Force random emoji for generic names
            final isGenericName =
                cleanName == 'รายการสินค้า' ||
                cleanName == 'สินค้า' ||
                cleanName == 'รายการ' ||
                cleanName == 'item';
            final emoji = EmojiUtils.generateEmoji(
              cleanName,
              additionalSeed: i,
              forceRandom: isGenericName,
            );

            items.add(
              Item(
                id: id,
                name: cleanName,
                price: price,
                emoji: emoji,
                ownerIds: [],
              ),
            );

            if (kDebugMode) {
              print('Parsed separated item: $cleanName - $price');
            }
          }
        } catch (e) {
          // Skip if price parsing fails
        }
      }
    }

    return items;
  }

  /// Check if a line should be skipped (not an item)
  static bool _isNonItemLine(String line) {
    final lowerLine = line.toLowerCase();

    // Skip common receipt headers/footers
    final skipPatterns = [
      'receipt', 'total', 'subtotal', 'tax', 'vat', 'discount', 'change',
      'cash', 'card', 'credit', 'thank', 'welcome', 'address', 'phone',
      'date', 'time', 'store', 'shop', 'company', 'ltd', 'co',
      'ใบเสร็จ', 'รวม', 'ยอดรวม', 'ภาษี', 'ส่วนลด', 'เงินทอน', 'เงินสด',
      'บัตร', 'ขอบคุณ', 'ยินดีต้อนรับ', 'ที่อยู่', 'เบอร์', 'วันที่', 'เวลา',
      'ร้าน', 'บริษัท',
    ];

    for (final pattern in skipPatterns) {
      if (lowerLine.contains(pattern)) return true;
    }

    // Skip lines that are only numbers or only letters
    if (RegExp(r'^\d+$').hasMatch(line)) return true;
    if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(line) && line.length < 4) return true;
    if (RegExp(r'^[\u0E00-\u0E7F\s]+$', unicode: true).hasMatch(line) &&
        line.length < 4) {
      return true;
    }

    // Skip lines that look like timestamps or IDs
    if (RegExp(r'\d{2}:\d{2}').hasMatch(line)) return true;
    if (RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(line)) return true;

    return false;
  }

  /// Validate OCR results and provide suggestions
  static Map<String, dynamic> validateOCRResults(
    List<Item> items, {
    String? rawText,
  }) {
    final issues = <String>[];
    final suggestions = <String>[];

    if (items.isEmpty) {
      issues.add('ไม่พบรายการใดจากการสแกน');

      // Check if OCR detected garbled text (common with poor image quality)
      if (rawText != null && _isGarbledText(rawText)) {
        suggestions.add('รูปภาพไม่ชัดเจน กรุณา:');
        suggestions.add('• ถ่ายรูปใหม่ในแสงที่ดีกว่า');
        suggestions.add('• ถือกล้องให้นิ่งและตั้งฉาก');
        suggestions.add('• ครอปให้เห็นเฉพาะบริเวณรายการอาหาร');
        suggestions.add('• ตรวจสอบว่าเลนส์กล้องสะอาด');
      } else {
        suggestions.add('ลองครอบรูปให้แค่บริเวณรายการอาหาร');
        suggestions.add('ตรวจสอบว่าแสงเพียงพอและข้อความชัดเจน');
        suggestions.add('หรือป้อนรายการด้วยตนเอง');
      }
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

  /// Check if OCR text appears to be garbled/corrupted
  static bool _isGarbledText(String text) {
    if (text.trim().isEmpty) return false;

    // Count invalid characters (non-Thai, non-English, non-numbers, non-common symbols)
    final invalidChars = RegExp(
      r'[^\w\s\d\.\-:฿,บาทราคาชิ้น\u0E00-\u0E7F\u0020-\u007E]',
      unicode: true,
    );
    final invalidMatches = invalidChars.allMatches(text).length;

    // If more than 30% of characters are invalid, consider it garbled
    final totalChars = text.replaceAll(RegExp(r'\s'), '').length;
    if (totalChars == 0) return false;

    final invalidRatio = invalidMatches / totalChars;

    // Also check for sequences of random characters
    final hasRandomSequences = RegExp(
      r'[a-zA-Z]{3,}[^\s\u0E00-\u0E7F]{2,}',
    ).hasMatch(text);

    return invalidRatio > 0.3 || hasRandomSequences;
  }

  /// Dispose resources
  static void dispose() {
    _textRecognizer.close();
  }
}