class Contract {
  final String id;
  final String contractId;
  final String roomId;
  final String tenantId;
  final double rentPrice;
  final double deposit;
  final int startDate;
  final int? endDate;
  final String status; // HIEU_LUC, KET_THUC
  final bool useWifi;
  final bool useTrash;
  final bool useServiceFee;
  final int lastElectric;
  final int lastWater;

  String get contractKey => contractId.isNotEmpty ? contractId : id;
  String get normalizedStatus => status.trim().toUpperCase();

  bool get isActive => [
        'HIEU_LUC',
        'DANG_HIEU_LUC',
        'ACTIVE',
      ].contains(normalizedStatus);
  bool get isEnded => [
        'KET_THUC',
        'DA_KET_THUC',
        'ENDED',
        'EXPIRED',
      ].contains(normalizedStatus);

  Contract({
    required this.id,
    this.contractId = '',
    required this.roomId,
    required this.tenantId,
    required this.rentPrice,
    required this.deposit,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.useWifi,
    required this.useTrash,
    required this.useServiceFee,
    this.lastElectric = 0,
    this.lastWater = 0,
  });

  factory Contract.fromFirestore(Map<String, dynamic> d, String id) => Contract(
        id: id,
        contractId: (d['contractId'] ?? '').toString(),
        roomId: (d['roomId'] ?? '').toString(),
        tenantId: (d['tenantId'] ?? '').toString(),
        rentPrice: _doubleValue(d['rentPrice']),
        deposit: _doubleValue(d['deposit']),
        startDate: _intValue(d['startDate']),
        endDate: d['endDate'] == null ? null : _intValue(d['endDate']),
        status: (d['status'] ?? 'HIEU_LUC').toString(),
        useWifi: _boolValue(d['useWifi']),
        useTrash: _boolValue(d['useTrash']),
        useServiceFee: _boolValue(d['useServiceFee']),
        lastElectric: _intValue(d['lastElectric']),
        lastWater: _intValue(d['lastWater']),
      );

  Map<String, dynamic> toMap() => {
        if (contractId.isNotEmpty) 'contractId': contractId,
        'roomId': roomId,
        'tenantId': tenantId,
        'rentPrice': rentPrice,
        'deposit': deposit,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
        'useWifi': useWifi,
        'useTrash': useTrash,
        'useServiceFee': useServiceFee,
        'lastElectric': lastElectric,
        'lastWater': lastWater,
      };
}

int _intValue(dynamic value) => int.tryParse((value ?? 0).toString()) ?? 0;
double _doubleValue(dynamic value) => double.tryParse((value ?? 0).toString()) ?? 0;
bool _boolValue(dynamic value) {
  if (value == true || value == 1 || value == 1.0) return true;
  final text = (value ?? '').toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}
