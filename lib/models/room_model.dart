class Room {
  final String id;
  final String roomId;
  final String roomName;
  final int floor;
  final double area;
  final double price;
  final String status; // TRONG, DANG_THUE, BAO_TRI
  final String note;
  final String imageUrl;
  final List<String> amenities;
  final double electricRate;
  final double waterRate;

  String get roomKey => roomId.isNotEmpty ? roomId : id;
  String get normalizedStatus => status.trim().toUpperCase();
  bool get isEmpty => ['TRONG', 'EMPTY', 'AVAILABLE'].contains(normalizedStatus);
  bool get isRented => ['DANG_THUE', 'RENTED', 'OCCUPIED', 'DA_THUE'].contains(normalizedStatus);
  bool get isMaintenance => normalizedStatus == 'BAO_TRI' || normalizedStatus == 'MAINTENANCE';

  Room({
    required this.id,
    this.roomId = '',
    required this.roomName,
    this.floor = 0,
    this.area = 0,
    required this.price,
    this.status = 'TRONG',
    this.note = '',
    this.imageUrl = '',
    this.amenities = const [],
    this.electricRate = 0,
    this.waterRate = 0,
  });

  factory Room.fromFirestore(Map<String, dynamic> d, String id) => Room(
        id: id,
        roomId: (d['roomId'] ?? '').toString(),
        roomName: d['roomName'] ?? '',
        floor: _intValue(d['floor']),
        area: _doubleValue(d['area']),
        price: _doubleValue(d['price']),
        status: d['status'] ?? 'TRONG',
        note: d['note'] ?? '',
        imageUrl: d['imageUrl'] ?? '',
        amenities: (d['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
        electricRate: _doubleValue(d['electricRate']),
        waterRate: _doubleValue(d['waterRate']),
      );

  Room copyWith({String? imageUrl, String? status, String? note}) => Room(
        id: id,
        roomId: roomId,
        roomName: roomName,
        floor: floor,
        area: area,
        price: price,
        status: status ?? this.status,
        note: note ?? this.note,
        imageUrl: imageUrl ?? this.imageUrl,
        amenities: amenities,
        electricRate: electricRate,
        waterRate: waterRate,
      );

  Map<String, dynamic> toMap() => {
        if (roomId.isNotEmpty) 'roomId': roomId,
        'roomName': roomName,
        'floor': floor,
        'area': area,
        'price': price,
        'status': status,
        'note': note,
        'imageUrl': imageUrl,
        'amenities': amenities,
        'electricRate': electricRate,
        'waterRate': waterRate,
      };
}

int _intValue(dynamic value) => int.tryParse((value ?? 0).toString()) ?? 0;
double _doubleValue(dynamic value) => double.tryParse((value ?? 0).toString()) ?? 0;
