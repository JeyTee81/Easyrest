import 'package:flutter/material.dart';

class Reservation {
  final int? id;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final DateTime reservationDate;
  final CustomTimeOfDay reservationTime;
  final int numberOfGuests;
  final List<int> tableIds; // IDs des tables réservées
  final String? specialRequests;
  final String status; // 'confirmed', 'cancelled', 'completed', 'no_show'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Reservation({
    this.id,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.reservationDate,
    required this.reservationTime,
    required this.numberOfGuests,
    required this.tableIds,
    this.specialRequests,
    this.status = 'confirmed',
    required this.createdAt,
    this.updatedAt,
  });

  // Créer une copie avec des valeurs modifiées
  Reservation copyWith({
    int? id,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    DateTime? reservationDate,
    CustomTimeOfDay? reservationTime,
    int? numberOfGuests,
    List<int>? tableIds,
    String? specialRequests,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      reservationDate: reservationDate ?? this.reservationDate,
      reservationTime: reservationTime ?? this.reservationTime,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      tableIds: tableIds ?? this.tableIds,
      specialRequests: specialRequests ?? this.specialRequests,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convertir en Map pour le stockage en base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'reservation_date': reservationDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'reservation_time': '${reservationTime.hour.toString().padLeft(2, '0')}:${reservationTime.minute.toString().padLeft(2, '0')}',
      'number_of_guests': numberOfGuests,
      'table_ids': tableIds.join(','), // Stocker comme string séparée par virgules
      'special_requests': specialRequests,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Créer depuis un Map
  factory Reservation.fromMap(Map<String, dynamic> map) {
    final timeParts = map['reservation_time'].split(':');
    final reservationTime = CustomTimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final tableIdsString = map['table_ids'] ?? '';
    final tableIds = tableIdsString.isEmpty 
        ? <int>[]
        : tableIdsString.split(',').map((id) => int.parse(id)).toList();

    return Reservation(
      id: map['id'],
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'],
      customerEmail: map['customer_email'],
      reservationDate: DateTime.parse(map['reservation_date']),
      reservationTime: reservationTime,
      numberOfGuests: map['number_of_guests'] ?? 0,
      tableIds: tableIds,
      specialRequests: map['special_requests'],
      status: map['status'] ?? 'confirmed',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // Obtenir le statut formaté
  String get statusDisplay {
    switch (status) {
      case 'confirmed':
        return 'Confirmée';
      case 'cancelled':
        return 'Annulée';
      case 'completed':
        return 'Terminée';
      case 'no_show':
        return 'Absent';
      default:
        return 'Inconnu';
    }
  }

  // Obtenir la couleur du statut
  Color get statusColor {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'no_show':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Obtenir l'icône du statut
  IconData get statusIcon {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      case 'no_show':
        return Icons.person_off;
      default:
        return Icons.help;
    }
  }

  // Vérifier si la réservation est pour aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return reservationDate.year == now.year &&
           reservationDate.month == now.month &&
           reservationDate.day == now.day;
  }

  // Vérifier si la réservation est pour demain
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return reservationDate.year == tomorrow.year &&
           reservationDate.month == tomorrow.month &&
           reservationDate.day == tomorrow.day;
  }

  // Vérifier si la réservation est passée
  bool get isPast {
    final now = DateTime.now();
    final reservationDateTime = DateTime(
      reservationDate.year,
      reservationDate.month,
      reservationDate.day,
      reservationTime.hour,
      reservationTime.minute,
    );
    return reservationDateTime.isBefore(now);
  }

  // Obtenir la capacité totale des tables réservées
  int get totalTableCapacity {
    // Cette méthode devra être complétée avec les données des tables
    // Pour l'instant, on retourne une estimation basée sur le nombre de tables
    return tableIds.length * 4; // Estimation de 4 personnes par table
  }

  @override
  String toString() {
    return 'Reservation(id: $id, customer: $customerName, date: $reservationDate, time: $reservationTime, guests: $numberOfGuests, tables: $tableIds, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reservation &&
           other.id == id &&
           other.customerName == customerName &&
           other.reservationDate == reservationDate &&
           other.reservationTime == reservationTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           customerName.hashCode ^
           reservationDate.hashCode ^
           reservationTime.hashCode;
  }
}

// Classe pour représenter une heure de la journée personnalisée
class CustomTimeOfDay {
  final int hour;
  final int minute;

  const CustomTimeOfDay({required this.hour, required this.minute});

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomTimeOfDay &&
           other.hour == hour &&
           other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

