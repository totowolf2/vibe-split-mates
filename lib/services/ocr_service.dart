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

  /// Enhance Thai text recognition through post-processing
  static String _enhanceThaiTextRecognition(String rawText) {
    if (rawText.isEmpty) return rawText;
    
    String enhanced = rawText;
    
    // Common OCR mistakes for Thai characters - fix them
    final thaiCorrections = {
      // Common misreads
      'yaL': 'ก',
      'ĂnlaslӦ': 'กุ้งทอด',
      'Srif': '',
      'enauu': 'เนื้อ',
      'Lws': 'ลาบ',
      'sn': 'หมู',
      '5înL5u': 'ส้มตำ',
      'nán': 'หมั่น',
      'nẩuN': 'เหนือ',
      // Common character confusions
      'Ă': 'ั',
      'ӦĦ': 'ำ',
      'Â': 'ี',
      'Ê': 'ื',
      'Ô': 'ุ',
      'Û': 'ู',
      // Number corrections
      '0O': '00',
      'o0': '00',
    };
    
    // Apply corrections
    thaiCorrections.forEach((wrong, correct) {
      enhanced = enhanced.replaceAll(wrong, correct);
    });
    
    // Clean up extra spaces and invalid characters
    enhanced = enhanced
        .replaceAll(RegExp(r'[^\w\s\d\.\-:฿,บาทราคาชิ้น\u0E00-\u0E7F\u0020-\u007E]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // If we still have garbled text, try to extract numbers at least
    if (_isGarbledText(enhanced)) {
      enhanced = _extractNumbersFromGarbledText(rawText);
    }
    
    return enhanced;
  }

  /// Extract price numbers from garbled text when OCR fails on Thai
  static String _extractNumbersFromGarbledText(String garbledText) {
    final lines = garbledText.split('\n');
    final cleanLines = <String>[];
    
    for (final line in lines) {
      // Look for price patterns even in garbled text
      final priceMatches = RegExp(r'(\d{1,4}(?:[,\.]\d{2})?)')
          .allMatches(line);
      
      if (priceMatches.isNotEmpty) {
        for (final match in priceMatches) {
          final price = match.group(1)!;
          // Add a generic Thai item name with the price
          cleanLines.add('รายการสินค้า $price');
        }
      }
    }
    
    return cleanLines.join('\n');
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

    // Try parsing raw text first (before enhancement)
    final reconstructedItems = _reconstructReceiptItems(rawLines);
    
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

  /// Reconstruct receipt items from scattered OCR lines
  static List<Map<String, dynamic>> _reconstructReceiptItems(List<String> lines) {
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
        if (price != null && price > 1 && price <= 9999) { // Changed from > 0 to > 1 to avoid confusion with quantities
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
    final maxItems = [quantities.length, possibleNames.length, prices.length].reduce((a, b) => a > b ? a : b);
    
    for (int i = 0; i < maxItems; i++) {
      final quantity = i < quantities.length ? quantities[i] : 1;
      final name = i < possibleNames.length ? possibleNames[i] : 'รายการสินค้า';
      final price = i < prices.length ? prices[i] : 0.0;
      
      if (price > 0) {
        items.add({
          'quantity': quantity,
          'name': name,
          'price': price,
        });
      }
    }
    
    return items;
  }

  /// Parse a reconstructed item data
  static Item? _parseReconstructedItem(Map<String, dynamic> itemData, [int? index]) {
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
      final id = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
      // Force random emoji for generic names like "รายการสินค้า"
      final isGenericName = name == 'รายการสินค้า' || name == 'สินค้า' || name == 'รายการ' || name == 'item';
      final emoji = EmojiUtils.generateEmoji(name, additionalSeed: index, forceRandom: isGenericName);
      
      return Item(
        id: id,
        name: name,
        price: price,
        emoji: emoji,
        ownerIds: [],
      );
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
    
    // Clean text for analysis
    final cleanText = text.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), ' ').trim();
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
    
    // Must be at least 50% English characters (lowered from 70%)
    if (englishRatio < 0.5) return false;
    
    // Check for common English patterns or recognizable words
    final words = cleanText.split(RegExp(r'\s+'));
    int recognizableWords = 0;
    
    for (final word in words) {
      if (word.length < 2) continue;
      
      // Check for common English word patterns
      if (_isLikelyEnglishWord(word)) {
        recognizableWords++;
        if (kDebugMode) {
          print('Found recognizable word: "$word"');
        }
      }
    }
    
    if (kDebugMode) {
      print('Recognizable words: $recognizableWords');
    }
    
    // For garbled text, be more strict - require at least one recognizable word
    return recognizableWords > 0;
  }

  /// Check if word looks like English
  static bool _isLikelyEnglishWord(String word) {
    if (word.length < 2) return false;
    
    // Only accept actual common English words, not garbled text
    final commonEnglishWords = {
      'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had', 
      'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his', 
      'how', 'its', 'may', 'new', 'now', 'old', 'see', 'two', 'way', 'who', 
      'boy', 'did', 'man', 'men', 'run', 'she', 'too', 'use', 'very', 'what', 
      'with', 'have', 'from', 'they', 'know', 'want', 'been', 'good', 'much', 
      'some', 'time', 'will', 'year', 'your', 'come', 'could', 'each', 'first', 
      'than', 'them', 'well', 'when', 'where', 'which', 'would', 'there', 'their', 
      'said', 'about', 'after', 'again', 'before', 'being', 'every', 'great', 
      'might', 'never', 'other', 'right', 'shall', 'still', 'these', 'those', 
      'under', 'water', 'while', 'world', 'food', 'drink', 'cake', 'bread', 
      'milk', 'water', 'coffee', 'tea', 'juice', 'beer', 'wine', 'soup', 
      'rice', 'meat', 'fish', 'chicken', 'beef', 'pork', 'egg', 'cheese', 
      'apple', 'banana', 'orange', 'pizza', 'burger', 'salad', 'sandwich'
    };
    
    // Check if it's a common English word
    if (commonEnglishWords.contains(word.toLowerCase())) {
      return true;
    }
    
    // Check for common English endings
    final englishSuffixes = ['ing', 'ed', 'er', 'est', 'ly', 'tion', 'ness', 'ment', 'able', 'ible'];
    for (final suffix in englishSuffixes) {
      if (word.endsWith(suffix) && word.length > suffix.length + 2) {
        return true;
      }
    }
    
    // Check for common English prefixes
    final englishPrefixes = ['un', 're', 'pre', 'dis', 'over', 'under'];
    for (final prefix in englishPrefixes) {
      if (word.startsWith(prefix) && word.length > prefix.length + 2) {
        return true;
      }
    }
    
    return false;
  }

  /// Check if text has English-like structure
  static bool _hasEnglishStructure(String text) {
    // Check for reasonable vowel-consonant distribution
    final vowels = RegExp(r'[aeiou]').allMatches(text).length;
    final consonants = RegExp(r'[bcdfghjklmnpqrstvwxyz]').allMatches(text).length;
    final total = vowels + consonants;
    
    if (total == 0) return false;
    
    final vowelRatio = vowels / total;
    // English typically has 35-45% vowels
    return vowelRatio >= 0.2 && vowelRatio <= 0.6;
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
        RegExp(r'^(.+?)\s+(?:฿|บาท)?(\d+(?:[,\.]\d{1,2})?)(?:\s*บาท)?$', unicode: true),

        // Pattern 2: "Item Name     12.50" (multiple spaces)
        RegExp(r'^(.+?)\s{2,}(?:฿|บาท)?(\d+(?:[,\.]\d{1,2})?)(?:\s*บาท)?$', unicode: true),

        // Pattern 3: "Item Name x1 12.50" or "Item Name 1x 12.50" or "Item Name 1 ชิ้น 12.50"
        RegExp(r'^(.+?)\s*(?:x?\d+|ชิ้น|\d+x?|\d+\s*ชิ้น)\s*(?:฿|บาท)?(\d+(?:[,\.]\d{1,2})?)(?:\s*บาท)?$', unicode: true),

        // Pattern 4: "12.50 Item Name" (price first)
        RegExp(r'^(?:฿|บาท)?(\d+(?:[,\.]\d{1,2})?)\s*(?:บาท)?\s+(.+?)$', unicode: true),

        // Pattern 5: "Item Name - 12.50" or "Item Name : 12.50"
        RegExp(r'^(.+?)\s*[-:]\s*(?:฿|บาท)?(\d+(?:[,\.]\d{1,2})?)(?:\s*บาท)?$', unicode: true),

        // Pattern 6: Thai specific patterns
        RegExp(r'^(.+?)\s+(?:ราคา|ราคา:\s*)?(?:฿|บาท)?(\d+(?:[,\.]\d{1,2})?)(?:\s*บาท)?$', unicode: true),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(cleanLine);
        if (match != null) {
          String name;
          double price;

          if (patterns.indexOf(pattern) == 3) {
            // Pattern 4: price first
            price = double.parse(match.group(1)!.replaceAll(',', '.'));
            name = match.group(2)!.trim();
          } else {
            // Other patterns: name first
            name = match.group(1)!.trim();
            price = double.parse(match.group(2)!.replaceAll(',', '.'));
          }

          // Validate extracted data
          if (name.isEmpty || price <= 0 || price > 99999) continue;

          // Clean the name
          name = _cleanItemName(name);
          if (name.isEmpty || name.length < 2) continue;

          // Generate unique ID and emoji
          final id =
              '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
          // Force random emoji for generic names  
          final isGenericName = name == 'รายการสินค้า' || name == 'สินค้า' || name == 'รายการ' || name == 'item';
          final emoji = EmojiUtils.generateEmoji(name, additionalSeed: DateTime.now().microsecond, forceRandom: isGenericName);

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
      final priceMatch = RegExp(r'^(?:฿|บาท)?(\d+(?:[,\.]\d{1,2})?)(?:\s*บาท)?$', unicode: true).firstMatch(priceLine.trim());
      
      if (priceMatch != null) {
        try {
          final price = double.parse(priceMatch.group(1)!.replaceAll(',', '.'));
          final cleanName = _cleanItemName(nameLine);
          
          if (cleanName.isNotEmpty && cleanName.length >= 2 && price > 0 && price <= 99999) {
            final id = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
            // Force random emoji for generic names
            final isGenericName = cleanName == 'รายการสินค้า' || cleanName == 'สินค้า' || cleanName == 'รายการ' || cleanName == 'item';
            final emoji = EmojiUtils.generateEmoji(cleanName, additionalSeed: i, forceRandom: isGenericName);
            
            items.add(Item(
              id: id,
              name: cleanName,
              price: price,
              emoji: emoji,
              ownerIds: [],
            ));
            
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

  /// Clean a line for better parsing
  static String _cleanLine(String line) {
    return line
        .replaceAll(
          RegExp(r'[^\w\s\d\.\-:฿,บาทราคาชิ้น\u0E00-\u0E7F]', unicode: true),
          '',
        ) // Remove special chars except common ones and Thai characters
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
    if (RegExp(r'^[\u0E00-\u0E7F\s]+$', unicode: true).hasMatch(line) && line.length < 4) return true;

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
        .replaceAll(RegExp(r'\d+\s*ชิ้น$', unicode: true), '') // Remove Thai quantity
        .replaceAll(RegExp(r'\s*[\-\:]\s*$'), '') // Remove trailing separators
        .replaceAll(RegExp(r'\s*ราคา\s*$', unicode: true), '') // Remove trailing "ราคา"
        .trim();
  }

  /// Validate OCR results and provide suggestions
  static Map<String, dynamic> validateOCRResults(List<Item> items, {String? rawText}) {
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
    final invalidChars = RegExp(r'[^\w\s\d\.\-:฿,บาทราคาชิ้น\u0E00-\u0E7F\u0020-\u007E]', unicode: true);
    final invalidMatches = invalidChars.allMatches(text).length;
    
    // If more than 30% of characters are invalid, consider it garbled
    final totalChars = text.replaceAll(RegExp(r'\s'), '').length;
    if (totalChars == 0) return false;
    
    final invalidRatio = invalidMatches / totalChars;
    
    // Also check for sequences of random characters
    final hasRandomSequences = RegExp(r'[a-zA-Z]{3,}[^\s\u0E00-\u0E7F]{2,}').hasMatch(text);
    
    return invalidRatio > 0.3 || hasRandomSequences;
  }

  /// Dispose resources
  static void dispose() {
    _textRecognizer.close();
  }
}
