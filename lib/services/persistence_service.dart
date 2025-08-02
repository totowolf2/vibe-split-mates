import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../models/person.dart';
import '../utils/constants.dart';

class PersistenceService {
  static const String _peopleKey = AppConstants.savedPeopleKey;

  // Singleton pattern
  static final PersistenceService _instance = PersistenceService._internal();
  factory PersistenceService() => _instance;
  PersistenceService._internal();

  SharedPreferences? _prefs;

  /// Initialize the persistence service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure SharedPreferences is initialized
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save list of people to persistent storage
  Future<bool> savePeople(List<Person> people) async {
    try {
      final prefs = await _preferences;
      final peopleJson = people.map((person) => person.toJson()).toList();
      final jsonString = jsonEncode(peopleJson);

      final success = await prefs.setString(_peopleKey, jsonString);

      if (kDebugMode) {
        print('Saved ${people.length} people to storage: $success');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving people to storage: $e');
      }
      return false;
    }
  }

  /// Load list of people from persistent storage
  Future<List<Person>> loadPeople() async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString(_peopleKey);

      if (jsonString == null || jsonString.isEmpty) {
        if (kDebugMode) {
          print('No saved people found in storage');
        }
        return [];
      }

      final List<dynamic> peopleJson = jsonDecode(jsonString);
      final people = peopleJson
          .map((json) => Person.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print('Loaded ${people.length} people from storage');
      }

      return people;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading people from storage: $e');
      }
      return [];
    }
  }

  /// Add a single person to storage
  Future<bool> addPerson(Person person) async {
    try {
      final currentPeople = await loadPeople();

      // Check if person already exists
      if (currentPeople.any((p) => p.id == person.id)) {
        if (kDebugMode) {
          print('Person with ID ${person.id} already exists');
        }
        return false;
      }

      currentPeople.add(person);
      return await savePeople(currentPeople);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding person to storage: $e');
      }
      return false;
    }
  }

  /// Remove a person from storage by ID
  Future<bool> removePerson(String personId) async {
    try {
      final currentPeople = await loadPeople();
      final initialCount = currentPeople.length;

      currentPeople.removeWhere((person) => person.id == personId);

      if (currentPeople.length == initialCount) {
        if (kDebugMode) {
          print('Person with ID $personId not found');
        }
        return false;
      }

      return await savePeople(currentPeople);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing person from storage: $e');
      }
      return false;
    }
  }

  /// Update an existing person in storage
  Future<bool> updatePerson(Person updatedPerson) async {
    try {
      final currentPeople = await loadPeople();
      final index = currentPeople.indexWhere((p) => p.id == updatedPerson.id);

      if (index == -1) {
        if (kDebugMode) {
          print('Person with ID ${updatedPerson.id} not found for update');
        }
        return false;
      }

      currentPeople[index] = updatedPerson;
      return await savePeople(currentPeople);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating person in storage: $e');
      }
      return false;
    }
  }

  /// Clear all saved people
  Future<bool> clearAllPeople() async {
    try {
      final prefs = await _preferences;
      final success = await prefs.remove(_peopleKey);

      if (kDebugMode) {
        print('Cleared all people from storage: $success');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing people from storage: $e');
      }
      return false;
    }
  }

  /// Check if a person exists by name (case-insensitive)
  Future<bool> personExistsByName(String name) async {
    try {
      final people = await loadPeople();
      return people.any(
        (person) => person.name.toLowerCase() == name.toLowerCase().trim(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if person exists by name: $e');
      }
      return false;
    }
  }

  /// Get a person by ID
  Future<Person?> getPersonById(String personId) async {
    try {
      final people = await loadPeople();
      final index = people.indexWhere((p) => p.id == personId);
      return index != -1 ? people[index] : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting person by ID: $e');
      }
      return null;
    }
  }

  /// Export people data as JSON string (for backup/sharing)
  Future<String?> exportPeopleAsJson() async {
    try {
      final people = await loadPeople();
      final exportData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'people': people.map((p) => p.toJson()).toList(),
      };
      return jsonEncode(exportData);
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting people data: $e');
      }
      return null;
    }
  }

  /// Import people data from JSON string (for backup/sharing)
  Future<bool> importPeopleFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> importData = jsonDecode(jsonString);

      if (!importData.containsKey('people')) {
        if (kDebugMode) {
          print('Invalid import data format: missing people key');
        }
        return false;
      }

      final List<dynamic> peopleJson = importData['people'];
      final people = peopleJson
          .map((json) => Person.fromJson(json as Map<String, dynamic>))
          .toList();

      return await savePeople(people);
    } catch (e) {
      if (kDebugMode) {
        print('Error importing people data: $e');
      }
      return false;
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final people = await loadPeople();
      final prefs = await _preferences;
      final jsonString = prefs.getString(_peopleKey) ?? '';

      return {
        'people_count': people.length,
        'storage_size_bytes': jsonString.length,
        'last_modified': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting storage stats: $e');
      }
      return {
        'people_count': 0,
        'storage_size_bytes': 0,
        'last_modified': null,
      };
    }
  }
}
