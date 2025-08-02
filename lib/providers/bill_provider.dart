import 'package:flutter/foundation.dart';
import 'dart:math';

import '../models/bill.dart';
import '../models/item.dart';
import '../models/person.dart';
import '../services/persistence_service.dart';

class BillProvider with ChangeNotifier {
  Bill? _currentBill;
  List<Person> _savedPeople = [];
  bool _isLoading = false;
  final PersistenceService _persistenceService = PersistenceService();

  // Getters
  Bill? get currentBill => _currentBill;
  List<Person> get savedPeople => List.unmodifiable(_savedPeople);
  List<Item> get items => _currentBill?.items ?? [];
  List<Person> get people => _currentBill?.people ?? [];
  bool get isLoading => _isLoading;

  // Calculation getters
  double get subtotal => _currentBill?.subtotal ?? 0.0;
  double get total => _currentBill?.total ?? 0.0;
  double get globalDiscountAmount => _currentBill?.globalDiscountAmount ?? 0.0;
  Map<String, double> get personShares =>
      _currentBill?.calculatePersonShares() ?? {};
  Map<String, double> get personDiscounts =>
      _currentBill?.calculatePersonDiscounts() ?? {};
  Map<String, List<String>> get personItemEmojis =>
      _currentBill?.getPersonItemEmojis() ?? {};

  BillProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await _persistenceService.init();
    _initializeBill();
    await _loadSavedPeople();
  }

  void _initializeBill() {
    _currentBill = Bill(id: _generateId(), items: [], people: []);
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  // People management
  Future<void> _loadSavedPeople() async {
    _setLoading(true);
    try {
      _savedPeople = await _persistenceService.loadPeople();
    } catch (e) {
      debugPrint('Error loading saved people: $e');
      _savedPeople = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addSavedPerson(Person person) async {
    try {
      // Check if person already exists
      if (_savedPeople.any(
        (p) =>
            p.id == person.id ||
            p.name.toLowerCase() == person.name.toLowerCase(),
      )) {
        return false;
      }

      final success = await _persistenceService.addPerson(person);
      if (success) {
        _savedPeople.add(person);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error adding saved person: $e');
      return false;
    }
  }

  Future<bool> removeSavedPerson(String personId) async {
    try {
      final success = await _persistenceService.removePerson(personId);
      if (success) {
        _savedPeople.removeWhere((p) => p.id == personId);

        // Also remove from current bill if present
        if (_currentBill != null) {
          final updatedPeople = _currentBill!.people
              .where((p) => p.id != personId)
              .toList();
          final updatedItems = _currentBill!.items
              .map((item) {
                final updatedOwners = item.ownerIds
                    .where((id) => id != personId)
                    .toList();
                return item.copyWith(ownerIds: updatedOwners);
              })
              .toList(); // Keep items even if they have no owners

          _currentBill = _currentBill!.copyWith(
            people: updatedPeople,
            items: updatedItems,
          );
        }

        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error removing saved person: $e');
      return false;
    }
  }

  Future<bool> updateSavedPerson(Person updatedPerson) async {
    try {
      // Check if a different person with the same name already exists
      if (_savedPeople.any(
        (p) =>
            p.id != updatedPerson.id &&
            p.name.toLowerCase() == updatedPerson.name.toLowerCase(),
      )) {
        return false;
      }

      final success = await _persistenceService.updatePerson(updatedPerson);
      if (success) {
        final index = _savedPeople.indexWhere((p) => p.id == updatedPerson.id);
        if (index != -1) {
          _savedPeople[index] = updatedPerson;
        }

        // Also update in current bill if present
        if (_currentBill != null) {
          final billPersonIndex = _currentBill!.people.indexWhere((p) => p.id == updatedPerson.id);
          if (billPersonIndex != -1) {
            final updatedPeople = [..._currentBill!.people];
            updatedPeople[billPersonIndex] = updatedPerson;
            _currentBill = _currentBill!.copyWith(people: updatedPeople);
          }
        }

        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error updating saved person: $e');
      return false;
    }
  }

  void addPersonToBill(Person person) {
    if (_currentBill == null) return;

    // Check if person already in bill
    if (_currentBill!.people.any((p) => p.id == person.id)) {
      return;
    }

    final updatedPeople = [..._currentBill!.people, person];
    _currentBill = _currentBill!.copyWith(people: updatedPeople);
    notifyListeners();
  }

  void removePersonFromBill(String personId) {
    if (_currentBill == null) return;

    final updatedPeople = _currentBill!.people
        .where((p) => p.id != personId)
        .toList();
    final updatedItems = _currentBill!.items
        .map((item) {
          final updatedOwners = item.ownerIds
              .where((id) => id != personId)
              .toList();
          return item.copyWith(ownerIds: updatedOwners);
        })
        .toList(); // Keep items even if they have no owners

    _currentBill = _currentBill!.copyWith(
      people: updatedPeople,
      items: updatedItems,
    );
    notifyListeners();
  }

  // Item management
  void addItem(Item item) {
    if (_currentBill == null) return;

    final updatedItems = [..._currentBill!.items, item];
    _currentBill = _currentBill!.copyWith(items: updatedItems);
    notifyListeners();
  }

  void addItems(List<Item> items) {
    if (_currentBill == null) return;

    final updatedItems = [..._currentBill!.items, ...items];
    _currentBill = _currentBill!.copyWith(items: updatedItems);
    notifyListeners();
  }

  void updateItem(String itemId, Item updatedItem) {
    if (_currentBill == null) return;

    final items = _currentBill!.items.map((item) {
      return item.id == itemId ? updatedItem : item;
    }).toList();

    _currentBill = _currentBill!.copyWith(items: items);
    notifyListeners();
  }

  void removeItem(String itemId) {
    if (_currentBill == null) return;

    final updatedItems = _currentBill!.items
        .where((item) => item.id != itemId)
        .toList();
    _currentBill = _currentBill!.copyWith(items: updatedItems);
    notifyListeners();
  }

  void addDiscountToItem(String itemId, double discount) {
    if (_currentBill == null) return;

    final items = _currentBill!.items.map((item) {
      return item.id == itemId ? item.copyWith(discount: discount) : item;
    }).toList();

    _currentBill = _currentBill!.copyWith(items: items);
    notifyListeners();
  }

  // Global discount management
  void setGlobalDiscount(BillDiscount? discount) {
    if (_currentBill == null) return;

    _currentBill = _currentBill!.copyWith(globalDiscount: discount);
    notifyListeners();
  }

  void removeGlobalDiscount() {
    setGlobalDiscount(null);
  }

  // Bill management
  void resetBill() {
    _initializeBill();
    notifyListeners();
  }

  void clearBillItems() {
    if (_currentBill == null) return;

    _currentBill = _currentBill!.copyWith(items: []);
    notifyListeners();
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Person? getPersonById(String personId) {
    return _currentBill?.people.firstWhere(
      (person) => person.id == personId,
      orElse: () => _savedPeople.firstWhere(
        (person) => person.id == personId,
        orElse: () => Person(id: personId, name: 'Unknown', avatar: '❓'),
      ),
    );
  }

  Item? getItemById(String itemId) {
    return _currentBill?.items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw StateError('Item not found'),
    );
  }

  // Check if this is the first item (for hint animation)
  bool get isFirstItem => _currentBill?.items.length == 1;

  // Check if bill has any items
  bool get hasItems => _currentBill?.items.isNotEmpty ?? false;

  // Check if bill has any people
  bool get hasPeople => _currentBill?.people.isNotEmpty ?? false;

  // Get summary data for export
  Map<String, dynamic> getBillSummary() {
    if (_currentBill == null) return {};

    final shares = personShares;
    final discounts = personDiscounts;

    return {
      'subtotal': subtotal,
      'globalDiscount': globalDiscountAmount,
      'total': total,
      'items': _currentBill!.items
          .map(
            (item) => {
              'name': item.name,
              'emoji': item.emoji,
              'price': item.price,
              'discountedPrice': item.discountedPrice,
              'owners': item.ownerIds
                  .map((id) => getPersonById(id)?.name ?? 'Unknown')
                  .toList(),
            },
          )
          .toList(),
      'people': _currentBill!.people
          .map(
            (person) => {
              'name': person.name,
              'avatar': person.avatar,
              'amountToPay': shares[person.id] ?? 0.0,
              'discountReceived': discounts[person.id] ?? 0.0,
            },
          )
          .toList(),
    };
  }
}
