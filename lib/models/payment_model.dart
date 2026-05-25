class Payment {
  final String id;
  final String billId;
  final double amount;
  final int paymentDate;

  Payment({
    required this.id,
    required this.billId,
    required this.amount,
    required this.paymentDate,
  });

  factory Payment.fromFirestore(Map<String, dynamic> d, String id) => Payment(
        id: id,
        billId: (d['billId'] ?? '').toString(),
        amount: double.tryParse((d['amount'] ?? 0).toString()) ?? 0,
        paymentDate: int.tryParse((d['paymentDate'] ?? 0).toString()) ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'billId': billId,
        'amount': amount,
        'paymentDate': paymentDate,
      };
}
