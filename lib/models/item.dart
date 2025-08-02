class Item {
  final String id;
  final String name;
  final double price;
  final String emoji;
  final List<String> ownerIds; // List of person IDs who share this item
  final double discount; // Individual item discount (amount in currency)

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.emoji,
    required this.ownerIds,
    this.discount = 0.0,
  });

  // Calculate discounted price
  double get discountedPrice {
    return (price - discount).clamp(0.0, double.infinity);
  }

  // Check if item has discount
  bool get hasDiscount => discount > 0;

  // Calculate price per person
  double get pricePerPerson {
    if (ownerIds.isEmpty) return 0.0;
    return discountedPrice / ownerIds.length;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'emoji': emoji,
      'ownerIds': ownerIds,
      'discount': discount,
    };
  }

  // JSON deserialization
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      emoji: json['emoji'] as String,
      ownerIds: List<String>.from(json['ownerIds'] as List),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // String representation
  @override
  String toString() {
    return 'Item(id: $id, name: $name, price: $price, emoji: $emoji, ownerIds: $ownerIds, discount: $discount)';
  }

  // Copy with method for updates
  Item copyWith({
    String? id,
    String? name,
    double? price,
    String? emoji,
    List<String>? ownerIds,
    double? discount,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      emoji: emoji ?? this.emoji,
      ownerIds: ownerIds ?? List<String>.from(this.ownerIds),
      discount: discount ?? this.discount,
    );
  }
}
