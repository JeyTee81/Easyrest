import '../utils/tva_utils.dart';
import '../utils/type_parsers.dart';

class MenuItem {
  final int? id;
  final String name;
  final double priceHt; // Price excluding TVA
  final double priceTtc; // Price including TVA
  final String tvaRate; // TVA rate (5.5%, 10%, 20%)
  final String description;
  final String category;
  final String? subcategory;
  final String type;
  final String printer;
  final bool isAvailable;
  final bool isPresetMenu; // New field to identify preset menus

  MenuItem({
    this.id,
    required this.name,
    required this.priceHt,
    required this.priceTtc,
    required this.tvaRate,
    required this.description,
    required this.category,
    this.subcategory,
    required this.type,
    required this.printer,
    required this.isAvailable,
    this.isPresetMenu = false,
  });

  // Get TVA amount
  double get tvaAmount => TvaUtils.calculateTvaAmount(priceHt, tvaRate);

  // Get formatted TVA rate
  String get formattedTvaRate => TvaUtils.formatTvaRate(tvaRate);

  // Check if it's a preset menu
  bool get isPreset => isPresetMenu || category.toLowerCase() == 'menus préétablis';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'priceHt': priceHt,
      'priceTtc': priceTtc,
      'tvaRate': tvaRate,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'type': type,
      'printer': printer,
      'isAvailable': isAvailable ? 1 : 0,
      'isPresetMenu': isPresetMenu ? 1 : 0,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      priceHt: parseDouble(map['price_ht'] ?? map['priceHt'] ?? map['price'] ?? 0.0),
      priceTtc: parseDouble(map['price_ttc'] ?? map['priceTtc'] ?? map['price'] ?? 0.0),
      tvaRate: map['tva_rate'] as String? ?? map['tvaRate'] as String? ?? TvaUtils.getDefaultTvaRate(),
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      subcategory: map['subcategory'] as String?,
      type: map['type'] as String? ?? '',
      printer: map['printer'] as String? ?? 'cuisine',
      isAvailable: parseBool(map['is_available'] ?? map['isAvailable']),
      isPresetMenu: parseBool(map['is_preset_menu'] ?? map['isPresetMenu']),
    );
  }

  // Create MenuItem with price excluding TVA
  factory MenuItem.withPriceHt({
    int? id,
    required String name,
    required double priceHt,
    required String tvaRate,
    required String description,
    required String category,
    String? subcategory,
    required String type,
    String printer = 'cuisine',
    required bool isAvailable,
    bool isPresetMenu = false,
  }) {
    final priceTtc = TvaUtils.calculatePriceTtc(priceHt, tvaRate);
    return MenuItem(
      id: id,
      name: name,
      priceHt: priceHt,
      priceTtc: priceTtc,
      tvaRate: tvaRate,
      description: description,
      category: category,
      subcategory: subcategory,
      type: type,
      printer: printer,
      isAvailable: isAvailable,
      isPresetMenu: isPresetMenu,
    );
  }

  // Create MenuItem with price including TVA
  factory MenuItem.withPriceTtc({
    int? id,
    required String name,
    required double priceTtc,
    required String tvaRate,
    required String description,
    required String category,
    String? subcategory,
    required String type,
    String printer = 'cuisine',
    required bool isAvailable,
    bool isPresetMenu = false,
  }) {
    final priceHt = TvaUtils.calculatePriceHt(priceTtc, tvaRate);
    return MenuItem(
      id: id,
      name: name,
      priceHt: priceHt,
      priceTtc: priceTtc,
      tvaRate: tvaRate,
      description: description,
      category: category,
      subcategory: subcategory,
      type: type,
      printer: printer,
      isAvailable: isAvailable,
      isPresetMenu: isPresetMenu,
    );
  }

  // Create preset menu
  factory MenuItem.presetMenu({
    int? id,
    required String name,
    required double priceTtc,
    String description = '',
    String printer = 'cuisine',
    bool isAvailable = true,
  }) {
    return MenuItem.withPriceTtc(
      id: id,
      name: name,
      priceTtc: priceTtc,
      tvaRate: '10%', // Default TVA rate for restaurant menus
      description: description,
      category: 'Menus préétablis',
      type: 'Menu',
      printer: printer,
      isAvailable: isAvailable,
      isPresetMenu: true,
    );
  }

  // Copy with modifications
  MenuItem copyWith({
    int? id,
    String? name,
    double? priceHt,
    double? priceTtc,
    String? tvaRate,
    String? description,
    String? category,
    String? subcategory,
    String? type,
    String printer = 'cuisine',
    bool? isAvailable,
    bool? isPresetMenu,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      priceHt: priceHt ?? this.priceHt,
      priceTtc: priceTtc ?? this.priceTtc,
      tvaRate: tvaRate ?? this.tvaRate,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      type: type ?? this.type,
      printer: printer ?? this.printer,
      isAvailable: isAvailable ?? this.isAvailable,
      isPresetMenu: isPresetMenu ?? this.isPresetMenu,
    );
  }
}

class PresetMenuItemLink {
  final int? id;
  final int presetMenuId;
  final int menuItemId;
  final String group; // ex : Entrée, Plat, Dessert, Boisson

  PresetMenuItemLink({
    this.id,
    required this.presetMenuId,
    required this.menuItemId,
    required this.group,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'presetMenuId': presetMenuId,
      'menuItemId': menuItemId,
      'group': group,
    };
  }

  factory PresetMenuItemLink.fromMap(Map<String, dynamic> map) {
    return PresetMenuItemLink(
      id: map['id'],
      presetMenuId: map['presetMenuId'],
      menuItemId: map['menuItemId'],
      group: map['group'],
    );
  }
}
