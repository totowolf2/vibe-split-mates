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
    'tom yum': '🍲',
    'som tam': '🥗',
    'mango': '🥭',
    'coconut': '🥥',
    'papaya': '🥭',
    'thai': '🇹🇭',

    // Fruits
    'apple': '🍎',
    'banana': '🍌',
    'orange': '🍊',
    'grape': '🍇',
    'strawberry': '🍓',
    'watermelon': '🍉',
    'pineapple': '🍍',
    'peach': '🍑',
    'cherry': '🍒',

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
    'taxi': '🚕',
    'uber': '🚗',
    'movie': '🎬',
    'ticket': '🎫',
    'hotel': '🏨',
    'shopping': '🛍️',
    'gift': '🎁',
    'book': '📚',
    'medicine': '💊',
    'phone': '📱',
    'delivery': '🚚',
    'tip': '💰',
    'service': '🔧',
    'parking': '🅿️',
  };

  // Default emoji for items that don't match any keywords
  static const String defaultEmoji = '🍽️';

  /// Generate emoji based on item name
  static String generateEmoji(String itemName) {
    final lowerName = itemName.toLowerCase().trim();

    // Check for exact matches first
    if (_keywordToEmoji.containsKey(lowerName)) {
      return _keywordToEmoji[lowerName]!;
    }

    // Check for partial matches
    for (final entry in _keywordToEmoji.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }

    return defaultEmoji;
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
