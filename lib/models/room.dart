class Room {
  final int? id;
  final String name;
  final String description;
  final bool isActive;

  const Room({
    this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      isActive: (map['is_active'] as bool?) ?? (map['isActive'] as int?) == 1,
    );
  }

  Room copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Room(id: $id, name: $name, description: $description, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Room &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ description.hashCode ^ isActive.hashCode;
  }
} 