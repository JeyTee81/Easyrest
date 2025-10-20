import '../utils/type_parsers.dart';

class Bill {
  final int? id;
  final int orderId;
  final String tableName;
  final double totalHt;
  final double totalTtc;
  final double totalTva;
  final String? paymentMethod; // Made optional for pending bills
  final DateTime createdAt;
  final String status; // 'pending', 'paid', 'cancelled', etc.
  final bool? archived; // Indicates if bill is archived after cash register closing (optional)

  Bill({
    this.id,
    required this.orderId,
    required this.tableName,
    required this.totalHt,
    required this.totalTtc,
    required this.totalTva,
    this.paymentMethod, // Made optional
    required this.createdAt,
    required this.status,
    this.archived, // Optional - may not exist in database
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'tableName': tableName,
      'totalHt': totalHt,
      'totalTtc': totalTtc,
      'totalTva': totalTva,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'archived': archived,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] as int?,
      orderId: parseInt(map['order_id'] ?? map['orderId'] ?? 0),
      tableName: map['table_name'] as String? ?? map['tableName'] as String? ?? 'Table inconnue',
      totalHt: parseDouble(map['total_ht'] ?? map['totalHt'] ?? 0.0),
      totalTtc: parseDouble(map['total_ttc'] ?? map['totalTtc'] ?? 0.0),
      totalTva: parseDouble(map['total_tva'] ?? map['totalTva'] ?? 0.0),
      paymentMethod: map['payment_method'] as String? ?? map['paymentMethod'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString())
          : map['createdAt'] != null 
              ? DateTime.parse(map['createdAt'].toString())
              : DateTime.now(),
      status: map['status'] as String? ?? 'pending',
      archived: map['archived'] as bool?,
    );
  }

  Bill copyWith({
    int? id,
    int? orderId,
    String? tableName,
    double? totalHt,
    double? totalTtc,
    double? totalTva,
    String? paymentMethod,
    DateTime? createdAt,
    String? status,
    bool? archived,
  }) {
    return Bill(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      tableName: tableName ?? this.tableName,
      totalHt: totalHt ?? this.totalHt,
      totalTtc: totalTtc ?? this.totalTtc,
      totalTva: totalTva ?? this.totalTva,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      archived: archived ?? this.archived,
    );
  }

  // Get formatted date
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  // Get formatted time
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  // Check if bill is from today
  bool get isFromToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
           createdAt.month == now.month &&
           createdAt.day == now.day;
  }

  // Get payment method icon
  String get paymentMethodIcon {
    if (paymentMethod == null) return '⏳'; // Pending icon
    switch (paymentMethod!.toLowerCase()) {
      case 'espèces':
        return '💵';
      case 'carte bancaire':
        return '💳';
      case 'ticket restaurant':
        return '🎫';
      case 'chèque':
        return '📄';
      default:
        return '💰';
    }
  }
} 