class Printer {
  final int? id;
  final String name;
  final String ipAddress;
  final int port;
  final String? location;
  final bool isActive;
  final String? description;

  const Printer({
    this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    this.location,
    this.isActive = true,
    this.description,
  });

  // Imprimantes prédéfinies
  static const List<Printer> defaultPrinters = [
    Printer(
      name: 'Cuisine',
      ipAddress: '192.168.1.100',
      port: 9100,
      location: 'Cuisine principale',
      description: 'Imprimante pour tous les plats et menus',
    ),
    Printer(
      name: 'Bar',
      ipAddress: '192.168.1.101',
      port: 9100,
      location: 'Bar',
      description: 'Imprimante pour les boissons',
    ),
    Printer(
      name: 'Entrées',
      ipAddress: '192.168.1.102',
      port: 9100,
      location: 'Cuisine froide',
      description: 'Imprimante pour les entrées',
    ),
    Printer(
      name: 'Desserts',
      ipAddress: '192.168.1.103',
      port: 9100,
      location: 'Pâtisserie',
      description: 'Imprimante pour les desserts',
    ),
  ];

  // Créer une copie avec des valeurs modifiées
  Printer copyWith({
    int? id,
    String? name,
    String? ipAddress,
    int? port,
    String? location,
    bool? isActive,
    String? description,
  }) {
    return Printer(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
    );
  }

  // Convertir en Map pour le stockage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ip_address': ipAddress,
      'port': port,
      'location': location,
      'is_active': isActive,
      'description': description,
    };
  }

  // Créer depuis un Map
  factory Printer.fromMap(Map<String, dynamic> map) {
    return Printer(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      ipAddress: map['ip_address'] as String? ?? '192.168.1.100',
      port: map['port'] as int? ?? 9100,
      location: map['location'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      description: map['description'] as String?,
    );
  }

  // Obtenir une imprimante par son ID
  static Printer? getById(int id) {
    try {
      return defaultPrinters.firstWhere((printer) => printer.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtenir une imprimante par son nom
  static Printer? getByName(String name) {
    try {
      return defaultPrinters.firstWhere((printer) => printer.name == name);
    } catch (e) {
      return null;
    }
  }

  // Obtenir toutes les imprimantes actives
  static List<Printer> getActivePrinters() {
    return defaultPrinters.where((printer) => printer.isActive).toList();
  }

  // Obtenir le nom d'une imprimante par son ID
  static String getPrinterName(int id) {
    final printer = getById(id);
    return printer?.name ?? 'Imprimante $id';
  }

  // Obtenir la localisation d'une imprimante par son ID
  static String getPrinterLocation(int id) {
    final printer = getById(id);
    return printer?.location ?? 'Non définie';
  }

  @override
  String toString() {
    return 'Printer(id: $id, name: $name, ipAddress: $ipAddress, port: $port, location: $location, isActive: $isActive, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Printer &&
        other.id == id &&
        other.name == name &&
        other.ipAddress == ipAddress &&
        other.port == port &&
        other.location == location &&
        other.isActive == isActive &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        ipAddress.hashCode ^
        port.hashCode ^
        location.hashCode ^
        isActive.hashCode ^
        description.hashCode;
  }
}