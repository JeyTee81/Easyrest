import '../utils/type_parsers.dart';

class CashRegisterOpening {
  final int? id;
  final DateTime date;
  final int shiftNumber; // 1, 2, 3... for multiple shifts per day
  final double initialCashAmount;
  final DateTime openedAt;
  final String openedBy;
  final String? notes;
  final bool isActive; // True if this opening hasn't been closed yet

  CashRegisterOpening({
    this.id,
    required this.date,
    required this.shiftNumber,
    required this.initialCashAmount,
    required this.openedAt,
    required this.openedBy,
    this.notes,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'shiftNumber': shiftNumber,
      'initialCashAmount': initialCashAmount,
      'openedAt': openedAt.toIso8601String(),
      'openedBy': openedBy,
      'notes': notes,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory CashRegisterOpening.fromMap(Map<String, dynamic> map) {
    return CashRegisterOpening(
      id: map['id'],
      date: _parseDateTime(map['date'] ?? map['created_at']),
      shiftNumber: map['shift_number'] ?? map['shiftNumber'] ?? 1,
      initialCashAmount: parseDouble(map['initial_cash_amount'] ?? map['initialCashAmount'] ?? 0.0),
      openedAt: _parseDateTime(map['opened_at'] ?? map['openedAt']),
      openedBy: map['opened_by'] ?? map['openedBy'] ?? '',
      notes: map['notes'],
      isActive: map['is_active'] == true || map['isActive'] == 1,
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

  CashRegisterOpening copyWith({
    int? id,
    DateTime? date,
    int? shiftNumber,
    double? initialCashAmount,
    DateTime? openedAt,
    String? openedBy,
    String? notes,
    bool? isActive,
  }) {
    return CashRegisterOpening(
      id: id ?? this.id,
      date: date ?? this.date,
      shiftNumber: shiftNumber ?? this.shiftNumber,
      initialCashAmount: initialCashAmount ?? this.initialCashAmount,
      openedAt: openedAt ?? this.openedAt,
      openedBy: openedBy ?? this.openedBy,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
} 