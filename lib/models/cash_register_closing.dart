import '../utils/type_parsers.dart';

class CashRegisterClosing {
  final int? id;
  final DateTime date;
  final int shiftNumber; // 1, 2, 3... for multiple shifts per day
  final double totalHt;
  final double totalTtc;
  final double totalTva;
  final Map<String, double> paymentMethods;
  final int numberOfBills;
  final double expectedCashAmount; // Initial cash + cash payments
  final double actualCashAmount; // Actual cash count at closing
  final double cashDifference; // actualCashAmount - expectedCashAmount
  final DateTime closedAt;
  final String closedBy;
  final String? notes;

  CashRegisterClosing({
    this.id,
    required this.date,
    required this.shiftNumber,
    required this.totalHt,
    required this.totalTtc,
    required this.totalTva,
    required this.paymentMethods,
    required this.numberOfBills,
    required this.expectedCashAmount,
    required this.actualCashAmount,
    required this.cashDifference,
    required this.closedAt,
    required this.closedBy,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'shiftNumber': shiftNumber,
      'totalHt': totalHt,
      'totalTtc': totalTtc,
      'totalTva': totalTva,
      'paymentMethods': _paymentMethodsToString(),
      'numberOfBills': numberOfBills,
      'expectedCashAmount': expectedCashAmount,
      'actualCashAmount': actualCashAmount,
      'cashDifference': cashDifference,
      'closedAt': closedAt.toIso8601String(),
      'closedBy': closedBy,
      'notes': notes,
    };
  }

  factory CashRegisterClosing.fromMap(Map<String, dynamic> map) {
    return CashRegisterClosing(
      id: map['id'],
      date: _parseDateTime(map['date']),
      shiftNumber: map['shift_number'] ?? map['shiftNumber'] ?? 1,
      totalHt: parseDouble(map['total_ht'] ?? map['totalHt'] ?? 0.0),
      totalTtc: parseDouble(map['total_ttc'] ?? map['totalTtc'] ?? 0.0),
      totalTva: parseDouble(map['total_tva'] ?? map['totalTva'] ?? 0.0),
      paymentMethods: _parsePaymentMethods(map['payment_methods'] ?? map['paymentMethods']),
      numberOfBills: map['number_of_bills'] ?? map['numberOfBills'] ?? 0,
      expectedCashAmount: parseDouble(map['expected_cash_amount'] ?? map['expectedCashAmount'] ?? 0.0),
      actualCashAmount: parseDouble(map['actual_cash_amount'] ?? map['actualCashAmount'] ?? 0.0),
      cashDifference: parseDouble(map['cash_difference'] ?? map['cashDifference'] ?? 0.0),
      closedAt: _parseDateTime(map['closed_at'] ?? map['closedAt']),
      closedBy: map['closed_by'] ?? map['closedBy'] ?? '',
      notes: map['notes'],
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  String _paymentMethodsToString() {
    return paymentMethods.entries
        .map((e) => '${e.key}:${e.value}')
        .join(';');
  }

  static Map<String, double> _parsePaymentMethods(dynamic value) {
    if (value == null) return {};
    
    if (value is Map<String, dynamic>) {
      // PostgreSQL retourne un objet JSON
      final Map<String, double> methods = {};
      value.forEach((key, val) {
        if (val is num) {
          methods[key] = val.toDouble();
        } else if (val is String) {
          methods[key] = double.tryParse(val) ?? 0.0;
        }
      });
      return methods;
    }
    
    if (value is String) {
      // Format string traditionnel
      return _stringToPaymentMethods(value);
    }
    
    return {};
  }

  static Map<String, double> _stringToPaymentMethods(String str) {
    final Map<String, double> methods = {};
    if (str.isNotEmpty) {
      for (final pair in str.split(';')) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          methods[parts[0]] = double.parse(parts[1]);
        }
      }
    }
    return methods;
  }

  CashRegisterClosing copyWith({
    int? id,
    DateTime? date,
    int? shiftNumber,
    double? totalHt,
    double? totalTtc,
    double? totalTva,
    Map<String, double>? paymentMethods,
    int? numberOfBills,
    double? expectedCashAmount,
    double? actualCashAmount,
    double? cashDifference,
    DateTime? closedAt,
    String? closedBy,
    String? notes,
  }) {
    return CashRegisterClosing(
      id: id ?? this.id,
      date: date ?? this.date,
      shiftNumber: shiftNumber ?? this.shiftNumber,
      totalHt: totalHt ?? this.totalHt,
      totalTtc: totalTtc ?? this.totalTtc,
      totalTva: totalTva ?? this.totalTva,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      numberOfBills: numberOfBills ?? this.numberOfBills,
      expectedCashAmount: expectedCashAmount ?? this.expectedCashAmount,
      actualCashAmount: actualCashAmount ?? this.actualCashAmount,
      cashDifference: cashDifference ?? this.cashDifference,
      closedAt: closedAt ?? this.closedAt,
      closedBy: closedBy ?? this.closedBy,
      notes: notes ?? this.notes,
    );
  }
} 