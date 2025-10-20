class Company {
  final String name;
  final String address;
  final String phone;
  final String vatNumber;
  final String siret;
  final String? email;
  final String? website;

  const Company({
    required this.name,
    required this.address,
    required this.phone,
    required this.vatNumber,
    required this.siret,
    this.email,
    this.website,
  });

  // Créer une entreprise vide pour l'initialisation
  factory Company.empty() {
    return const Company(
      name: '',
      address: '',
      phone: '',
      vatNumber: '',
      siret: '',
    );
  }

  // Créer une copie avec des valeurs modifiées
  Company copyWith({
    String? name,
    String? address,
    String? phone,
    String? vatNumber,
    String? siret,
    String? email,
    String? website,
  }) {
    return Company(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      vatNumber: vatNumber ?? this.vatNumber,
      siret: siret ?? this.siret,
      email: email ?? this.email,
      website: website ?? this.website,
    );
  }

  // Convertir en Map pour le stockage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'vatNumber': vatNumber,
      'siret': siret,
      'email': email,
      'website': website,
    };
  }

  // Créer depuis un Map
  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      vatNumber: map['vatNumber'] ?? '',
      siret: map['siret'] ?? '',
      email: map['email'],
      website: map['website'],
    );
  }

  // Vérifier si l'entreprise est configurée
  bool get isConfigured {
    return name.isNotEmpty && 
           address.isNotEmpty && 
           phone.isNotEmpty && 
           vatNumber.isNotEmpty && 
           siret.isNotEmpty;
  }

  // Vérifier si tous les champs obligatoires sont remplis
  bool get isComplete {
    return name.isNotEmpty && 
           address.isNotEmpty && 
           phone.isNotEmpty && 
           vatNumber.isNotEmpty && 
           siret.isNotEmpty;
  }

  @override
  String toString() {
    return 'Company(name: $name, address: $address, phone: $phone, vatNumber: $vatNumber, siret: $siret, email: $email, website: $website)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company &&
        other.name == name &&
        other.address == address &&
        other.phone == phone &&
        other.vatNumber == vatNumber &&
        other.siret == siret &&
        other.email == email &&
        other.website == website;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        address.hashCode ^
        phone.hashCode ^
        vatNumber.hashCode ^
        siret.hashCode ^
        email.hashCode ^
        website.hashCode;
  }
}









