import '../utils/type_parsers.dart';

class TableRestaurant {
  final int? id;
  final int number;
  final int capacity;
  final int roomId;
  final String status;

  TableRestaurant({
    this.id,
    required this.number,
    required this.capacity,
    required this.roomId,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'capacity': capacity,
      'roomId': roomId,
      'status': status,
    };
  }

  factory TableRestaurant.fromMap(Map<String, dynamic> map) {
    return TableRestaurant(
      id: map['id'] as int?,
      number: parseInt(map['number'] ?? map['table_number'] ?? 0),
      capacity: parseInt(map['capacity'] ?? 0),
      roomId: parseInt(map['room_id'] ?? map['roomId'] ?? 0),
      status: map['status'] as String? ?? 'Libre',
    );
  }
} 