import '../utils/tva_utils.dart';
import '../utils/type_parsers.dart';

class OrderItem {
  final int? id;
  final int? orderId;
  final int menuItemId;
  final String name;
  final int quantity;
  final double priceHt; // Price excluding TVA
  final double priceTtc; // Price including TVA
  final String tvaRate; // TVA rate
  final double totalHt; // Total excluding TVA
  final double totalTtc; // Total including TVA
  final double totalTva; // Total TVA amount
  final String? specialInstructions;

  // Propriétés de commodité pour la compatibilité
  int get productId => menuItemId;
  String get productName => name;
  double get unitPrice => priceTtc;
  double get totalPrice => totalTtc;

  OrderItem({
    this.id,
    this.orderId,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.priceHt,
    required this.priceTtc,
    required this.tvaRate,
    required this.totalHt,
    required this.totalTtc,
    required this.totalTva,
    this.specialInstructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'priceHt': priceHt,
      'priceTtc': priceTtc,
      'tvaRate': tvaRate,
      'totalHt': totalHt,
      'totalTtc': totalTtc,
      'totalTva': totalTva,
      'specialInstructions': specialInstructions,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['order_id'] as int? ?? map['orderId'] as int?,
      menuItemId: parseInt(map['menu_item_id'] ?? map['menuItemId'] ?? 0),
      name: map['name'] as String? ?? '',
      quantity: parseInt(map['quantity'] ?? 1),
      priceHt: parseDouble(map['price_ht'] ?? map['priceHt']),
      priceTtc: parseDouble(map['price_ttc'] ?? map['priceTtc']),
      tvaRate: map['tva_rate'] as String? ?? map['tvaRate'] as String? ?? TvaUtils.getDefaultTvaRate(),
      totalHt: parseDouble(map['total_ht'] ?? map['totalHt']),
      totalTtc: parseDouble(map['total_ttc'] ?? map['totalTtc']),
      totalTva: parseDouble(map['total_tva'] ?? map['totalTva']),
      specialInstructions: map['special_instructions'] as String? ?? map['specialInstructions'] as String?,
    );
  }

  // Create OrderItem from MenuItem
  factory OrderItem.fromMenuItem(int menuItemId, String name, double priceHt, double priceTtc, String tvaRate, int quantity, {int? orderId}) {
    final totalHt = priceHt * quantity;
    final totalTtc = priceTtc * quantity;
    final totalTva = TvaUtils.calculateTvaAmount(priceHt, tvaRate) * quantity;

    return OrderItem(
      orderId: orderId,
      menuItemId: menuItemId,
      name: name,
      quantity: quantity,
      priceHt: priceHt,
      priceTtc: priceTtc,
      tvaRate: tvaRate,
      totalHt: totalHt,
      totalTtc: totalTtc,
      totalTva: totalTva,
      specialInstructions: null,
    );
  }

  // Copy with modifications
  OrderItem copyWith({
    int? id,
    int? orderId,
    int? menuItemId,
    String? name,
    int? quantity,
    double? priceHt,
    double? priceTtc,
    String? tvaRate,
    double? totalHt,
    double? totalTtc,
    double? totalTva,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      priceHt: priceHt ?? this.priceHt,
      priceTtc: priceTtc ?? this.priceTtc,
      tvaRate: tvaRate ?? this.tvaRate,
      totalHt: totalHt ?? this.totalHt,
      totalTtc: totalTtc ?? this.totalTtc,
      totalTva: totalTva ?? this.totalTva,
    );
  }
}
