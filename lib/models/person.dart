class Person {
  final String id;
  final String name;
  final String avatar; // Emoji or image path
  final String? imagePath; // Profile picture file path

  Person({
    required this.id,
    required this.name,
    required this.avatar,
    this.imagePath,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'avatar': avatar, 'imagePath': imagePath};
  }

  // JSON deserialization
  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      imagePath: json['imagePath'] as String?,
    );
  }

  // Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // String representation
  @override
  String toString() {
    return 'Person(id: $id, name: $name, avatar: $avatar, imagePath: $imagePath)';
  }

  // Copy with method for updates
  Person copyWith({
    String? id,
    String? name,
    String? avatar,
    String? imagePath,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  // Helper to check if person has a profile picture
  bool get hasProfilePicture => imagePath != null && imagePath!.isNotEmpty;
}
