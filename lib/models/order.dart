import 'order_item.dart';
import '../utils/tva_utils.dart';

class Order {
  final int? id;
  final int tableId;
  final String tableName;
  final String? staffName;
  final List<OrderItem> items;
  final String status; // en cours, terminé, payé
  final double totalHt; // Total excluding TVA
  final double totalTtc; // Total including TVA
  final double totalTva; // Total TVA amount
  final DateTime createdAt;

  Order({
    this.id,
    required this.tableId,
    required this.tableName,
    this.staffName,
    required this.items,
    required this.status,
    required this.totalHt,
    required this.totalTtc,
    required this.totalTva,
    required this.createdAt,
  });

  // Get total amount (backward compatibility)
  double get totalAmount => totalTtc;

  // Get TVA breakdown by rate
  Map<String, double> get tvaBreakdown {
    final breakdown = <String, double>{};
    for (final item in items) {
      breakdown[item.tvaRate] = (breakdown[item.tvaRate] ?? 0) + item.totalTva;
    }
    return breakdown;
  }

  // Get subtotal by TVA rate
  Map<String, double> get subtotalByTvaRate {
    final subtotals = <String, double>{};
    for (final item in items) {
      subtotals[item.tvaRate] = (subtotals[item.tvaRate] ?? 0) + item.totalHt;
    }
    return subtotals;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tableId': tableId,
      'tableName': tableName,
      'staffName': staffName,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status,
      'totalHt': totalHt,
      'totalTtc': totalTtc,
      'totalTva': totalTva,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    List<OrderItem> orderItems = [];
    
    // Handle both new and old format
    if (map['items'] is List) {
      // New format with OrderItem objects
      orderItems = (map['items'] as List)
          .map((item) => OrderItem.fromMap(item))
          .toList();
    } else if (map['items'] is String) {
      // Old format - convert to new format
      final itemIds = (map['items'] as String).split(',').map((e) => int.parse(e)).toList();
      // Note: This is a simplified conversion. In a real app, you'd need to fetch the actual menu items
      for (final itemId in itemIds) {
        orderItems.add(OrderItem.fromMenuItem(
          itemId,
          'Item $itemId', // Placeholder name
          0.0, // Placeholder price
          0.0, // Placeholder price
          TvaUtils.getDefaultTvaRate(),
          1, // Default quantity
          orderId: map['id'], // Use the order ID from the map
        ));
      }
    }

    return Order(
      id: map['id'] as int?,
      tableId: map['table_id'] ?? map['tableId'] ?? 0, // Handle both formats and null values
      tableName: map['table_name'] ?? map['tableName'] ?? 'Table ${map['table_id'] ?? map['tableId'] ?? 0}',
      staffName: map['staff_name'] ?? map['staffName'],
      items: orderItems,
      status: map['status'] ?? 'en cours',
      totalHt: _parseDouble(map['total_ht'] ?? map['totalHt'] ?? map['totalAmount'] ?? 0.0),
      totalTtc: _parseDouble(map['total_ttc'] ?? map['totalTtc'] ?? map['totalAmount'] ?? 0.0),
      totalTva: _parseDouble(map['total_tva'] ?? map['totalTva'] ?? 0.0),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString())
          : map['createdAt'] != null 
              ? DateTime.parse(map['createdAt'].toString())
              : DateTime.now(),
    );
  }

  // Create Order from items
  factory Order.fromItems({
    int? id,
    required int tableId,
    required List<OrderItem> items,
    required String status,
    DateTime? createdAt,
  }) {
    final totalHt = items.fold(0.0, (sum, item) => sum + item.totalHt);
    final totalTtc = items.fold(0.0, (sum, item) => sum + item.totalTtc);
    final totalTva = items.fold(0.0, (sum, item) => sum + item.totalTva);

    return Order(
      id: id,
      tableId: tableId,
      tableName: 'Table $tableId',
      staffName: null,
      items: items,
      status: status,
      totalHt: totalHt,
      totalTtc: totalTtc,
      totalTva: totalTva,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  // Copy with modifications
  Order copyWith({
    int? id,
    int? tableId,
    List<OrderItem>? items,
    String? status,
    double? totalHt,
    double? totalTtc,
    double? totalTva,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableName: this.tableName,
      staffName: this.staffName,
      items: items ?? this.items,
      status: status ?? this.status,
      totalHt: totalHt ?? this.totalHt,
      totalTtc: totalTtc ?? this.totalTtc,
      totalTva: totalTva ?? this.totalTva,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Add item to order
  Order addItem(OrderItem item) {
    final newItems = List<OrderItem>.from(items)..add(item);
    return Order.fromItems(
      id: id,
      tableId: tableId,
      items: newItems,
      status: status,
      createdAt: createdAt,
    );
  }

  // Remove item from order
  Order removeItem(int itemId) {
    final newItems = items.where((item) => item.id != itemId).toList();
    return Order.fromItems(
      id: id,
      tableId: tableId,
      items: newItems,
      status: status,
      createdAt: createdAt,
    );
  }

  // Update item quantity
  Order updateItemQuantity(int itemId, int newQuantity) {
    final newItems = items.map((item) {
      if (item.id == itemId) {
        return OrderItem.fromMenuItem(
          item.menuItemId,
          item.name,
          item.priceHt,
          item.priceTtc,
          item.tvaRate,
          newQuantity,
          orderId: item.orderId,
        );
      }
      return item;
    }).toList();

    return Order.fromItems(
      id: id,
      tableId: tableId,
      items: newItems,
      status: status,
      createdAt: createdAt,
    );
  }

  // Helper method to parse double values from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
} 