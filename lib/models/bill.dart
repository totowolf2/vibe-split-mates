import 'item.dart';
import 'person.dart';

enum DiscountType { amount, percentage }

enum DiscountSplitType { equal, proportional }

class BillDiscount {
  final double value;
  final DiscountType type;
  final DiscountSplitType splitType;

  BillDiscount({
    required this.value,
    required this.type,
    required this.splitType,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'type': type.toString(),
      'splitType': splitType.toString(),
    };
  }

  // JSON deserialization
  factory BillDiscount.fromJson(Map<String, dynamic> json) {
    return BillDiscount(
      value: (json['value'] as num).toDouble(),
      type: DiscountType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => DiscountType.amount,
      ),
      splitType: DiscountSplitType.values.firstWhere(
        (e) => e.toString() == json['splitType'],
        orElse: () => DiscountSplitType.equal,
      ),
    );
  }
}

class Bill {
  final String id;
  final List<Item> items;
  final List<Person> people;
  final BillDiscount? globalDiscount;
  final DateTime createdAt;

  Bill({
    required this.id,
    required this.items,
    required this.people,
    this.globalDiscount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate total before global discount
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.discountedPrice);
  }

  // Calculate global discount amount
  double get globalDiscountAmount {
    if (globalDiscount == null) return 0.0;

    switch (globalDiscount!.type) {
      case DiscountType.amount:
        return globalDiscount!.value;
      case DiscountType.percentage:
        return subtotal * (globalDiscount!.value / 100);
    }
  }

  // Calculate final total after all discounts
  double get total {
    return (subtotal - globalDiscountAmount).clamp(0.0, double.infinity);
  }

  // Calculate individual person's share
  Map<String, double> calculatePersonShares() {
    final shares = <String, double>{};

    // Initialize all people with 0
    for (final person in people) {
      shares[person.id] = 0.0;
    }

    // Calculate each person's share from items
    for (final item in items) {
      for (final ownerId in item.ownerIds) {
        shares[ownerId] = (shares[ownerId] ?? 0.0) + item.pricePerPerson;
      }
    }

    // Apply global discount
    if (globalDiscount != null && globalDiscountAmount > 0) {
      final totalBeforeGlobalDiscount = shares.values.fold(
        0.0,
        (sum, share) => sum + share,
      );

      if (totalBeforeGlobalDiscount > 0) {
        switch (globalDiscount!.splitType) {
          case DiscountSplitType.equal:
            // Split discount equally among all people
            final discountPerPerson = globalDiscountAmount / people.length;
            for (final person in people) {
              shares[person.id] = (shares[person.id]! - discountPerPerson)
                  .clamp(0.0, double.infinity);
            }
            break;
          case DiscountSplitType.proportional:
            // Split discount proportionally based on each person's share
            for (final person in people) {
              final proportion = shares[person.id]! / totalBeforeGlobalDiscount;
              final personalDiscount = globalDiscountAmount * proportion;
              shares[person.id] = (shares[person.id]! - personalDiscount).clamp(
                0.0,
                double.infinity,
              );
            }
            break;
        }
      }
    }

    return shares;
  }

  // Calculate individual person's discount benefit
  Map<String, double> calculatePersonDiscounts() {
    final discounts = <String, double>{};

    // Initialize all people with 0
    for (final person in people) {
      discounts[person.id] = 0.0;
    }

    // Calculate discount from individual items
    for (final item in items) {
      if (item.hasDiscount) {
        final discountPerPerson = item.discount / item.ownerIds.length;
        for (final ownerId in item.ownerIds) {
          discounts[ownerId] = (discounts[ownerId] ?? 0.0) + discountPerPerson;
        }
      }
    }

    // Add global discount
    if (globalDiscount != null && globalDiscountAmount > 0) {
      final shares = <String, double>{};
      for (final person in people) {
        shares[person.id] = 0.0;
      }

      // Calculate original shares (without item discounts)
      for (final item in items) {
        final originalPricePerPerson = item.price / item.ownerIds.length;
        for (final ownerId in item.ownerIds) {
          shares[ownerId] = (shares[ownerId] ?? 0.0) + originalPricePerPerson;
        }
      }

      final totalBeforeGlobalDiscount = shares.values.fold(
        0.0,
        (sum, share) => sum + share,
      );

      if (totalBeforeGlobalDiscount > 0) {
        switch (globalDiscount!.splitType) {
          case DiscountSplitType.equal:
            final discountPerPerson = globalDiscountAmount / people.length;
            for (final person in people) {
              discounts[person.id] =
                  (discounts[person.id] ?? 0.0) + discountPerPerson;
            }
            break;
          case DiscountSplitType.proportional:
            for (final person in people) {
              final proportion = shares[person.id]! / totalBeforeGlobalDiscount;
              final personalDiscount = globalDiscountAmount * proportion;
              discounts[person.id] =
                  (discounts[person.id] ?? 0.0) + personalDiscount;
            }
            break;
        }
      }
    }

    return discounts;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'people': people.map((person) => person.toJson()).toList(),
      'globalDiscount': globalDiscount?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // JSON deserialization
  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      items: (json['items'] as List)
          .map((itemJson) => Item.fromJson(itemJson))
          .toList(),
      people: (json['people'] as List)
          .map((personJson) => Person.fromJson(personJson))
          .toList(),
      globalDiscount: json['globalDiscount'] != null
          ? BillDiscount.fromJson(json['globalDiscount'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Copy with method for updates
  Bill copyWith({
    String? id,
    List<Item>? items,
    List<Person>? people,
    BillDiscount? globalDiscount,
    DateTime? createdAt,
  }) {
    return Bill(
      id: id ?? this.id,
      items: items ?? List<Item>.from(this.items),
      people: people ?? List<Person>.from(this.people),
      globalDiscount: globalDiscount ?? this.globalDiscount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Bill(id: $id, items: ${items.length}, people: ${people.length}, total: $total)';
  }
}
