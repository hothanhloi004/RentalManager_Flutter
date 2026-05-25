class Asset {
  String id;
  String roomId;
  String name;
  int quantity;
  String note;
  int createdAt;

  Asset({
    required this.id,
    required this.roomId,
    required this.name,
    this.quantity = 1,
    this.note = '',
    required this.createdAt,
  });

  factory Asset.fromFirestore(Map<String, dynamic> data, String id) {
    return Asset(
      id: id,
      roomId: (data['roomId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      quantity: _intValue(data['quantity'], fallback: 1),
      note: (data['note'] ?? '').toString(),
      createdAt: _intValue(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'name': name,
      'quantity': quantity,
      'note': note,
      'createdAt': createdAt,
    };
  }
}

int _intValue(dynamic value, {int fallback = 0}) =>
    int.tryParse((value ?? fallback).toString()) ?? fallback;

