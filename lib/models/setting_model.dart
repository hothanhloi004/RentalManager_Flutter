class Setting {
  final double electricPrice;
  final double waterPrice;
  final double serviceFee;
  final double trashFee;
  final double wifiPrice;
  final String bankCode;
  final String bankAccount;
  final String hostelName;
  final String landlordName;
  final String landlordPhone;
  final String hostelAddress;
  final bool pinEnabled;
  final String? pinCode;

  Setting({
    this.electricPrice = 3500,
    this.waterPrice = 20000,
    this.serviceFee = 0,
    this.trashFee = 30000,
    this.wifiPrice = 0,
    this.bankCode = 'MB',
    this.bankAccount = '',
    this.hostelName = '',
    this.landlordName = '',
    this.landlordPhone = '',
    this.hostelAddress = '',
    this.pinEnabled = false,
    this.pinCode,
  });

  factory Setting.fromFirestore(Map<String, dynamic> d) => Setting(
        electricPrice: double.tryParse((d['electricPrice'] ?? 3500).toString()) ?? 3500,
        waterPrice: double.tryParse((d['waterPrice'] ?? 20000).toString()) ?? 20000,
        serviceFee: double.tryParse((d['serviceFee'] ?? 0).toString()) ?? 0,
        trashFee: double.tryParse((d['trashFee'] ?? 30000).toString()) ?? 30000,
        wifiPrice: double.tryParse((d['wifiPrice'] ?? 0).toString()) ?? 0,
        bankCode: d['bankCode']?.toString() ?? d['bank_code']?.toString() ?? d['nganhang']?.toString() ?? 'MB',
        bankAccount: d['bankAccount']?.toString() ?? d['bank_account']?.toString() ?? d['sotaikhoan']?.toString() ?? d['accountNumber']?.toString() ?? '',
        hostelName: d['hostelName']?.toString() ?? d['motelName']?.toString() ?? d['tenNhaTro']?.toString() ?? d['ten_nha_tro']?.toString() ?? '',
        landlordName: d['landlordName']?.toString() ?? d['ownerName']?.toString() ?? d['tenChuTro']?.toString() ?? d['ten_chu_tro']?.toString() ?? '',
        landlordPhone: d['landlordPhone']?.toString() ?? d['ownerPhone']?.toString() ?? d['sdtChuTro']?.toString() ?? d['phone']?.toString() ?? '',
        hostelAddress: d['hostelAddress']?.toString() ?? d['motelAddress']?.toString() ?? d['diaChiNhaTro']?.toString() ?? d['address']?.toString() ?? '',
        pinEnabled: d['pinEnabled'] == true ||
            d['pinEnabled'] == 'true' ||
            d['pinEnabled'] == 1 ||
            d['pinEnabled'] == 1.0,
        pinCode: d['pinCode']?.toString() ?? d['pin']?.toString(),
      );

  Map<String, dynamic> toMap() => {
        'electricPrice': electricPrice,
        'waterPrice': waterPrice,
        'serviceFee': serviceFee,
        'trashFee': trashFee,
        'wifiPrice': wifiPrice,
        'bankCode': bankCode,
        'bankAccount': bankAccount,
        'hostelName': hostelName,
        'landlordName': landlordName,
        'landlordPhone': landlordPhone,
        'hostelAddress': hostelAddress,
        'pinEnabled': pinEnabled ? 1 : 0,
        'pinCode': pinCode,
      };
}
