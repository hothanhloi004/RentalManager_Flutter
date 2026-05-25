class Tenant {
  final String id;
  final String tenantId;
  final String fullName;
  final String phone;
  final String cccd;
  final String address;
  final int moveInDate;
  final double deposit;
  final String roomId;
  final List<String> imageUrls;

  String get tenantKey => tenantId.isNotEmpty ? tenantId : id;

  Tenant({
    required this.id,
    this.tenantId = '',
    required this.fullName,
    required this.phone,
    required this.cccd,
    required this.address,
    this.moveInDate = 0,
    this.deposit = 0,
    this.roomId = '',
    this.imageUrls = const [],
  });

  factory Tenant.fromFirestore(Map<String, dynamic> d, String id) => Tenant(
        id: id,
        tenantId: (d['tenantId'] ?? '').toString(),
        fullName: (d['fullName'] ?? '').toString(),
        phone: (d['phone'] ?? '').toString(),
        cccd: (d['cccd'] ?? '').toString(),
        address: (d['address'] ?? '').toString(),
        moveInDate: _intValue(d['moveInDate']),
        deposit: _doubleValue(d['deposit']),
        roomId: (d['roomId'] ?? '').toString(),
        imageUrls: _stringList(d['imageUrls']),
      );

  Map<String, dynamic> toMap() => {
        if (tenantId.isNotEmpty) 'tenantId': tenantId,
        'fullName': fullName,
        'phone': phone,
        'cccd': cccd,
        'address': address,
        'moveInDate': moveInDate,
        'deposit': deposit,
        'roomId': roomId,
        'imageUrls': imageUrls,
      };

  Tenant copyWith({
    String? id,
    String? tenantId,
    String? fullName,
    String? phone,
    String? cccd,
    String? address,
    int? moveInDate,
    double? deposit,
    String? roomId,
    List<String>? imageUrls,
  }) =>
      Tenant(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        cccd: cccd ?? this.cccd,
        address: address ?? this.address,
        moveInDate: moveInDate ?? this.moveInDate,
        deposit: deposit ?? this.deposit,
        roomId: roomId ?? this.roomId,
        imageUrls: imageUrls ?? this.imageUrls,
      );
}

int _intValue(dynamic value) => int.tryParse((value ?? 0).toString()) ?? 0;
double _doubleValue(dynamic value) => double.tryParse((value ?? 0).toString()) ?? 0;
List<String> _stringList(dynamic value) {
  if (value is Iterable) {
    return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
  }
  final single = (value ?? '').toString().trim();
  return single.isEmpty ? const [] : [single];
}
