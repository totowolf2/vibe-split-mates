class EmojiUtils {
  // Mapping of keywords to emojis for auto-assignment
  static const Map<String, String> _keywordToEmoji = {
    // Food items
    'pizza': '🍕',
    'burger': '🍔',
    'fries': '🍟',
    'hotdog': '🌭',
    'sandwich': '🥪',
    'taco': '🌮',
    'burrito': '🌯',
    'salad': '🥗',
    'pasta': '🍝',
    'ramen': '🍜',
    'soup': '🍲',
    'curry': '🍛',
    'rice': '🍚',
    'bread': '🍞',
    'cake': '🍰',
    'pie': '🥧',
    'cookie': '🍪',
    'donut': '🍩',
    'ice cream': '🍦',
    'icecream': '🍦',

    // Drinks
    'coffee': '☕',
    'tea': '🍵',
    'beer': '🍺',
    'wine': '🍷',
    'cocktail': '🍸',
    'juice': '🧃',
    'soda': '🥤',
    'water': '💧',
    'milk': '🥛',
    'smoothie': '🥤',

    // Thai food
    'pad thai': '🍜',
    'ผัดไทย': '🍜',
    'tom yum': '🍲',
    'ต้มยำ': '🍲',
    'som tam': '🥗',
    'ส้มตำ': '🥗',
    'mango': '🥭',
    'มะม่วง': '🥭',
    'coconut': '🥥',
    'มะพร้าว': '🥥',
    'papaya': '🥭',
    'มะละกอ': '🥭',
    'thai': '🇹🇭',
    'ข้าว': '🍚',
    'น้ำ': '🥤',
    'เบียร์': '🍺',
    'กาแฟ': '☕',
    'ชา': '🍵',
    'ลาบ': '🥗',
    'แกงเขียวหวาน': '🍛',
    'แกง': '🍛',
    'ก๋วยเตี๋ยว': '🍜',
    'ข้าวผัด': '🍚',
    'ไก่': '🍗',
    'หมู': '🥓',
    'ปลา': '🐟',
    'กุ้ง': '🍤',
    'ปู': '🦀',

    // Fruits
    'apple': '🍎',
    'แอปเปิ้ล': '🍎',
    'banana': '🍌',
    'กล้วย': '🍌',
    'orange': '🍊',
    'ส้ม': '🍊',
    'grape': '🍇',
    'องุ่น': '🍇',
    'strawberry': '🍓',
    'สตรอเบอรี่': '🍓',
    'watermelon': '🍉',
    'แตงโม': '🍉',
    'pineapple': '🍍',
    'สับปะรด': '🍍',
    'peach': '🍑',
    'ลูกพีช': '🍑',
    'cherry': '🍒',
    'เชอรี่': '🍒',

    // Vegetables
    'tomato': '🍅',
    'carrot': '🥕',
    'corn': '🌽',
    'pepper': '🌶️',
    'mushroom': '🍄',
    'onion': '🧅',
    'garlic': '🧄',

    // Meat & Seafood
    'chicken': '🍗',
    'beef': '🥩',
    'pork': '🥓',
    'fish': '🐟',
    'shrimp': '🍤',
    'crab': '🦀',
    'lobster': '🦞',

    // Other
    'gas': '⛽',
    'น้ำมัน': '⛽',
    'taxi': '🚕',
    'แท็กซี่': '🚕',
    'uber': '🚗',
    'grab': '🚗',
    'รถ': '🚗',
    'movie': '🎬',
    'หนัง': '🎬',
    'ticket': '🎫',
    'ตั๋ว': '🎫',
    'hotel': '🏨',
    'โรงแรม': '🏨',
    'shopping': '🛍️',
    'ช้อปปิ้ง': '🛍️',
    'ซื้อของ': '🛍️',
    'gift': '🎁',
    'ของขวัญ': '🎁',
    'book': '📚',
    'หนังสือ': '📚',
    'medicine': '💊',
    'ยา': '💊',
    'phone': '📱',
    'โทรศัพท์': '📱',
    'มือถือ': '📱',
    'delivery': '🚚',
    'เดลิเวอรี่': '🚚',
    'ส่งของ': '🚚',
    'tip': '💰',
    'ทิป': '💰',
    'service': '🔧',
    'บริการ': '🔧',
    'parking': '🅿️',
    'จอดรถ': '🅿️',

    // OCR common results
    'รายการสินค้า': '', // Empty string will trigger random emoji
    'สินค้า': '', // Empty string will trigger random emoji
    'รายการ': '', // Empty string will trigger random emoji
    'item': '', // Empty string will trigger random emoji
  };

  // Default emoji for items that don't match any keywords
  static const String defaultEmoji = '🍽️';

  // Diverse random emojis for when no specific match is found
  static const List<String> _randomFunEmojis = [
    // Food variety
    '🍕', '🍔', '🍟', '🌭', '🥪', '🌮', '🌯', '🥗', '🍝', '🍜',
    '🍲', '🍛', '🍚', '🍞', '🧀', '🥓', '🍳', '🥞', '🧇', '🥨',
    '🍖', '🍗', '🥩', '🌶️', '🥒', '🥬', '🥑', '🍅', '🧄', '🧅',
    '🥕', '🌽', '🥦', '🥔', '🍠', '🫘', '🥜', '🌰', '🍄', '🫐',

    // Drinks variety
    '☕', '🍵', '🧃', '🥤', '🧋', '🍶', '🍾', '🍷', '🍸', '🍹',
    '🍺', '🍻', '🥂', '🥛', '🫖', '🧊', '💧', '🥥', '🍯', '🫙',

    // Fruits
    '🍎', '🍌', '🍊', '🍇', '🍓', '🍉', '🍍', '🥭', '🍑', '🍒',
    '🥝', '🫒', '🥥', '🍈', '🍋', '🥔', '🫚', '🌶️',

    // Fun decorative
    '🎉', '✨', '🌟', '⭐', '🎊', '🎈', '🎁', '🎀', '🌈', '🦄',
    '🎯', '🎪', '🎨', '🎭', '🎮', '🎲', '🍀', '🌸', '🌺', '🌻',
    '🌼', '💫', '⚡', '🔥', '❤️', '💖', '💝', '🎵', '🎶', '🎼',
    '🌙', '☀️', '💎', '🎡', '🎢', '🎠', '🖼️', '🎪',

    // Objects and items
    '📱', '💻', '⌚', '📷', '🎧', '🎤', '🎮', '🕹️', '🎲', '🃏',
    '🎯', '🎳', '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏓',
    '🥅', '⛳', '🏹', '🎣', '🛷', '🛼', '🛹', '🛴', '🚲',
  ];

  /// Generate emoji based on item name
  static String generateEmoji(
    String itemName, {
    int? additionalSeed,
    bool forceRandom = false,
  }) {
    final lowerName = itemName.toLowerCase().trim();

    // Check for exact matches first (unless forced random)
    if (!forceRandom && _keywordToEmoji.containsKey(lowerName)) {
      final emoji = _keywordToEmoji[lowerName]!;
      // If emoji is empty string, use random emoji instead
      if (emoji.isEmpty) {
        return _getRandomEmoji(itemName, additionalSeed);
      }
      return emoji;
    }

    // Check for partial matches (unless forced random)
    if (!forceRandom) {
      for (final entry in _keywordToEmoji.entries) {
        if (lowerName.contains(entry.key)) {
          final emoji = entry.value;
          // If emoji is empty string, use random emoji instead
          if (emoji.isEmpty) {
            return _getRandomEmoji(itemName, additionalSeed);
          }
          return emoji;
        }
      }
    }

    // If no match found or forced random, return a random emoji
    return _getRandomEmoji(itemName, additionalSeed);
  }

  /// Get a truly random emoji with multiple entropy sources
  static String _getRandomEmoji(String itemName, int? additionalSeed) {
    final now = DateTime.now();
    final hash = itemName.hashCode.abs();
    final nameLength = itemName.length;
    final firstChar = itemName.isNotEmpty ? itemName.codeUnitAt(0) : 0;

    // Use multiple entropy sources for true randomness
    final seed = additionalSeed ?? 0;
    final timeEntropy = now.millisecondsSinceEpoch + now.microsecond;
    final randomSeed =
        (hash * 31 +
            nameLength * 17 +
            firstChar * 13 +
            seed * 7 +
            timeEntropy * 3) %
        1000000;

    // Use a simple linear congruential generator for better distribution
    final random = (randomSeed * 1103515245 + 12345) % _randomFunEmojis.length;
    return _randomFunEmojis[random];
  }

  /// Get all available emojis for manual selection
  static List<String> getAllFoodEmojis() {
    return [
      '🍕',
      '🍔',
      '🍟',
      '🌭',
      '🥪',
      '🌮',
      '🌯',
      '🥗',
      '🍝',
      '🍜',
      '🍲',
      '🍛',
      '🍚',
      '🍞',
      '🍰',
      '🥧',
      '🍪',
      '🍩',
      '🍦',
      '☕',
      '🍵',
      '🍺',
      '🍷',
      '🍸',
      '🧃',
      '🥤',
      '💧',
      '🥛',
      '🍎',
      '🍌',
      '🍊',
      '🍇',
      '🍓',
      '🍉',
      '🍍',
      '🍑',
      '🍒',
      '🥭',
      '🥥',
      '🍅',
      '🥕',
      '🌽',
      '🌶️',
      '🍄',
      '🧅',
      '🧄',
      '🍗',
      '🥩',
      '🥓',
      '🐟',
      '🍤',
      '🦀',
      '🦞',
      '⛽',
      '🚕',
      '🚗',
      '🎬',
      '🎫',
      '🏨',
      '🛍️',
      '🎁',
      '📚',
      '💊',
      '📱',
      '🚚',
      '💰',
      '🔧',
      '🅿️',
      '🍽️',
    ];
  }

  /// Check if a string is a valid emoji
  static bool isEmoji(String text) {
    return text.isNotEmpty &&
        text.runes.length == 1 &&
        text.runes.first > 0x1F000;
  }

  /// Get emoji for person avatar (different from food emojis)
  static List<String> getPersonEmojis() {
    return [
      '👤',
      '👥',
      '👨',
      '👩',
      '👦',
      '👧',
      '🧑',
      '👴',
      '👵',
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🥸',
      '🤩',
      '🥳',
      '😏',
      '😒',
      '😞',
      '😔',
      '😟',
      '😕',
      '🙁',
      '☹️',
      '😣',
      '😖',
      '😫',
      '😩',
      '🥺',
    ];
  }
}
