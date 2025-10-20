import '../utils/tva_utils.dart';
import '../utils/type_parsers.dart';

class Product {
  final int? id;
  final String name;
  final int quantity;
  final int minQuantity;
  final String unit;
  final String description;
  final double priceHt; // Purchase price excluding TVA
  final double priceTtc; // Purchase price including TVA
  final String tvaRate; // TVA rate for purchase

  Product({
    this.id,
    required this.name,
    required this.quantity,
    required this.minQuantity,
    required this.unit,
    required this.description,
    required this.priceHt,
    required this.priceTtc,
    required this.tvaRate,
  });

  // Get TVA amount for purchase
  double get tvaAmount => TvaUtils.calculateTvaAmount(priceHt, tvaRate);

  // Get formatted TVA rate
  String get formattedTvaRate => TvaUtils.formatTvaRate(tvaRate);

  // Get total value excluding TVA
  double get totalValueHt => priceHt * quantity;

  // Get total value including TVA
  double get totalValueTtc => priceTtc * quantity;

  // Get total TVA amount
  double get totalTvaAmount => tvaAmount * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unit': unit,
      'description': description,
      'priceHt': priceHt,
      'priceTtc': priceTtc,
      'tvaRate': tvaRate,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      minQuantity: map['min_quantity'] ?? map['minQuantity'] ?? 0,
      unit: map['unit'] ?? '',
      description: map['description'] ?? '',
      priceHt: parseDouble(map['price_ht'] ?? map['priceHt'] ?? 0.0),
      priceTtc: parseDouble(map['price_ttc'] ?? map['priceTtc'] ?? 0.0),
      tvaRate: map['tva_rate'] ?? map['tvaRate'] ?? TvaUtils.getDefaultTvaRate(),
    );
  }

  // Create Product with price excluding TVA
  factory Product.withPriceHt({
    int? id,
    required String name,
    required int quantity,
    required int minQuantity,
    required String unit,
    required String description,
    required double priceHt,
    required String tvaRate,
  }) {
    final priceTtc = TvaUtils.calculatePriceTtc(priceHt, tvaRate);
    return Product(
      id: id,
      name: name,
      quantity: quantity,
      minQuantity: minQuantity,
      unit: unit,
      description: description,
      priceHt: priceHt,
      priceTtc: priceTtc,
      tvaRate: tvaRate,
    );
  }

  // Create Product with price including TVA
  factory Product.withPriceTtc({
    int? id,
    required String name,
    required int quantity,
    required int minQuantity,
    required String unit,
    required String description,
    required double priceTtc,
    required String tvaRate,
  }) {
    final priceHt = TvaUtils.calculatePriceHt(priceTtc, tvaRate);
    return Product(
      id: id,
      name: name,
      quantity: quantity,
      minQuantity: minQuantity,
      unit: unit,
      description: description,
      priceHt: priceHt,
      priceTtc: priceTtc,
      tvaRate: tvaRate,
    );
  }

  // Copy with modifications
  Product copyWith({
    int? id,
    String? name,
    int? quantity,
    int? minQuantity,
    String? unit,
    String? description,
    double? priceHt,
    double? priceTtc,
    String? tvaRate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      priceHt: priceHt ?? this.priceHt,
      priceTtc: priceTtc ?? this.priceTtc,
      tvaRate: tvaRate ?? this.tvaRate,
    );
  }
} 