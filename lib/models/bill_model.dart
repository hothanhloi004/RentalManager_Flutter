class Bill {
  final String id;
  final String billId;
  final String contractId;
  final String month;
  final int oldElectric;
  final int newElectric;
  final int electricUsed;
  final int oldWater;
  final int newWater;
  final int waterUsed;
  final double electricPrice;
  final double waterPrice;
  final double rentPrice;
  final double serviceFee;
  final double totalAmount;
  final String paymentStatus; // CHUA_THANH_TOAN, DONG_THIEU, DA_THANH_TOAN, paid, unpaid
  final int dueDate;
  final int? paidAt;
  final bool meterUpdated;

  String get normalizedStatus => paymentStatus.trim().toUpperCase();
  bool get isPaid => ['DA_THANH_TOAN', 'PAID'].contains(normalizedStatus);
  bool get isUnpaid => ['CHUA_THANH_TOAN', 'UNPAID'].contains(normalizedStatus);
  bool get isPartial => ['DONG_THIEU', 'PARTIAL', 'THIEU'].contains(normalizedStatus);
  String get paymentKey => billId.isNotEmpty ? billId : id;
  int get effectiveElectricUsed {
    final byMeter = newElectric - oldElectric;
    return byMeter > 0 ? byMeter : electricUsed;
  }

  int get effectiveWaterUsed {
    final byMeter = newWater - oldWater;
    return byMeter > 0 ? byMeter : waterUsed;
  }

  Bill({
    required this.id,
    this.billId = '',
    required this.contractId,
    required this.month,
    required this.oldElectric,
    required this.newElectric,
    required this.electricUsed,
    required this.oldWater,
    required this.newWater,
    required this.waterUsed,
    required this.electricPrice,
    required this.waterPrice,
    required this.rentPrice,
    required this.serviceFee,
    required this.totalAmount,
    required this.paymentStatus,
    required this.dueDate,
    this.paidAt,
    this.meterUpdated = false,
  });

  factory Bill.fromFirestore(Map<String, dynamic> d, String id) => Bill(
        id: id,
        billId: (d['billId'] ?? '').toString(),
        contractId: (d['contractId'] ?? '').toString(),
        month: (d['month'] ?? '').toString(),
        oldElectric: _intValue(d['oldElectric']),
        newElectric: _intValue(d['newElectric']),
        electricUsed: _intValue(d['electricUsed']),
        oldWater: _intValue(d['oldWater']),
        newWater: _intValue(d['newWater']),
        waterUsed: _intValue(d['waterUsed']),
        electricPrice: _doubleValue(d['electricPrice']),
        waterPrice: _doubleValue(d['waterPrice']),
        rentPrice: _doubleValue(d['rentPrice']),
        serviceFee: _doubleValue(d['serviceFee']),
        totalAmount: _doubleValue(d['totalAmount']),
        paymentStatus: (d['paymentStatus'] ?? 'CHUA_THANH_TOAN').toString(),
        dueDate: _intValue(d['dueDate']),
        paidAt: d['paidAt'] == null ? null : _intValue(d['paidAt']),
        meterUpdated: _boolValue(d['meterUpdated']),
      );

  Map<String, dynamic> toMap() => {
        if (billId.isNotEmpty) 'billId': billId,
        'contractId': contractId,
        'month': month,
        'oldElectric': oldElectric,
        'newElectric': newElectric,
        'electricUsed': electricUsed,
        'oldWater': oldWater,
        'newWater': newWater,
        'waterUsed': waterUsed,
        'electricPrice': electricPrice,
        'waterPrice': waterPrice,
        'rentPrice': rentPrice,
        'serviceFee': serviceFee,
        'totalAmount': totalAmount,
        'paymentStatus': paymentStatus,
        'dueDate': dueDate,
        'paidAt': paidAt,
        'meterUpdated': meterUpdated,
      };
}

int _intValue(dynamic value) => int.tryParse((value ?? 0).toString()) ?? 0;
double _doubleValue(dynamic value) => double.tryParse((value ?? 0).toString()) ?? 0;
bool _boolValue(dynamic value) {
  if (value == true || value == 1 || value == 1.0) return true;
  final text = (value ?? '').toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}
