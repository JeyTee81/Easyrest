class Staff {
  final int? id;
  final String name;
  final String pin;
  final String role;
  final bool isActive;

  Staff({
    this.id,
    required this.name,
    required this.pin,
    required this.role,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'role': role,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'],
      name: map['name'] ?? '',
      pin: map['pin'] ?? '',
      role: map['role'] ?? '',
      isActive: map['is_active'] == true || map['isActive'] == 1,
    );
  }
} 